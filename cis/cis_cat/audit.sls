{% from "cis/map.jinja" import cis_settings with context %}

{# Run CIS-CAT to generate an up to date report file #}
{# TODO - offer configurable output file name #}

{# ensure the assessor is installed and pre-req's exist appropriately #}
include:
  - cis.cis_cat.assessor

{% set java_args = cis_settings.cis_cat.assessor.java_args %}
{% set args = cis_settings.cis_cat.assessor.arguments %}
{% set reports_dir = cis_settings.lookup.locations.cis_cat.assessor.reports %}

{% set profile = cis_settings.cis_cat.assessor.profile %}
{% set benchmark = cis_settings.cis_cat.assessor.benchmark %}

{# determine report name to use #}
{% set report_name = grains.id %}
{% if 'report_name' in cis_settings.audit and cis_settings.audit.report_name != '' %}
{% set report_name = cis_settings.audit.report_name %}
{% endif %}

{# add -TIMESTAMP to the filename #}
{% if cis_settings.audit.timestamp == True %}
{% set report_name = report_name + "-" + None|strftime(cis_settings.audit.timestamp_format) %}
{% endif %}

{% set args = args + " --report-name \"" + report_name + "\" --results-dir \"" + reports_dir + "\"" %}

{% set report_extension = cis_settings.audit.format %}
{% set report_file = report_name + "." + report_extension %}

{% if cis_settings.audit.destination != 'ccpd' %}
{% if cis_settings.audit.format == 'oval-html' %}
{% set args = args + " --oval-results" %}
{% set report_extension = 'html' %}
{% endif %}

{% if cis_settings.audit.format == 'oval-xml' %}
{% set args = args + " --oval-results-xml" %}
{% set report_extension = 'html' %}
{% endif %}

{% if cis_settings.audit.format == 'xml' %}
{% set args = args + " --report-xml" %}
{% endif %}

{% if cis_settings.audit.format == 'arf' %}
{% set args = args + " --report-arf" %}
{% endif %}

{% if cis_settings.audit.format == 'txt' %}
{% set args = args + " --report-txt" %}
{% endif %}

{% if cis_settings.audit.format == 'csv' %}
{% set args = args + " --report-csv" %}
{% endif %}
{% endif %}

{% if benchmark != '' and profile != '' %}
  {# benchmark and profile MUST both be specified for manual specification to work #}
  {% set args = args + " --benchmark \"benchmarks/" + benchmark + "\" --profile \"" + profile + "\"" %}
{% else %}
  {# automatically determine appropriate benchmark #}
  {# auto-assess at level 1 by default #}
  {% set args = args + " --auto-assess" %}
  {% if cis_settings.cis_cat.assessor.auto_assess == 2 %}
    {# auto-assess at level 2 #}
    {% set args = args + " --auto-assess-level2" %}
  {% endif %}
{% endif %}

{% if cis_settings.audit.destination == 'ccpd' and cis_settings.audit.ccpd.token != {} and cis_settings.audit.ccpd.url != '' %}
  {% set args = args + " --report-xml --report-no-html --report-upload \"" + cis_settings.audit.ccpd.url + "\" -D ciscat.post.parameter.ccpd.token=" + cis_settings.audit.ccpd.token %}
{% endif %}

{# actually runs the java command #}
cis_cat_report_run:
  cmd.run:
    - name: 'java {{ java_args }} -jar {{ cis_settings.lookup.locations.cis_cat.assessor.install }}/CISCAT.jar {{ args }}'
    - cwd: '/tmp'
{% if 'source' in cis_settings.cis_cat.assessor and cis_settings.cis_cat.assessor.source != '' %}
    - require:
      - archive: cis-cat-assessor-extract
{% endif %}

{% if cis_settings.audit.destination == 'master' %}

{% set upload_path = "/cis-cat/" + report_file %}
{% if cis_settings.audit.master.upload_path != '' %}
{% set upload_path = cis_settings.audit.master.upload_path + "/" + report_file %}
{% endif %}

cis_cat_report_push:
  module.run:
    - name: cp.push
    - path: {{ reports_dir }}/{{ report_file }}
    - upload_path: {{ upload_path }}

cis/audit/report/available:
  event.send:
    - data:
      filename: {{ upload_path }}
    - require:
      - module: cis_cat_report_push

{% if cis_settings.audit.s3.bucket != '' %}
s3_report_push:
  module.run:
    - name: s3_custom.put
    - kwargs:
      bucket: {{ cis_settings.audit.s3.bucket }}
      path: {{ report_file }}
      local_file: {{ reports_dir }}/{{ report_file }}
    - require:
      - event: cis/audit/report/available
{% endif %}

{% endif %}

{# EOF #}
