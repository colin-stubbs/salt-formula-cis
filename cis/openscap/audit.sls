{% from "cis/map.jinja" import cis_settings with context %}

{# Run oscap to generate an up to date report file #}

include:
  - cis.openscap.oscap

{% set args = cis_settings.openscap.oscap.arguments %}
{% set reports_dir = cis_settings.lookup.locations.openscap.oscap.reports %}

{% set profile = cis_settings.openscap.oscap.profile %}
{% set benchmark = cis_settings.openscap.oscap.benchmark %}

{# determine report name to use #}
{% set report_name = grains.id %}
{% if 'report_name' in cis_settings.audit and cis_settings.audit.report_name != '' %}
{% set report_name = cis_settings.audit.report_name %}
{% endif %}

{# add -TIMESTAMP to the filename #}
{% if cis_settings.audit.timestamp == True %}
{% set report_name = report_name + "-" + None|strftime(cis_settings.audit.timestamp_format) %}
{% endif %}

{% set report_extension = cis_settings.audit.format %}
{% set report_file = report_name + "." + report_extension %}

{% if cis_settings.audit.format== 'html' %}
{% set args = args + " --report \"" + reports_dir + "/" + report_name + ".html\"" %}
{% endif %}

{% if cis_settings.audit.format== 'xml' %}
{% set args = args + " --results \"" + reports_dir + "/" + report_name + ".xml\"" %}
{% endif %}

{% if cis_settings.audit.format== 'arf' %}
{% set args = args + " --results-arf \"" + reports_dir + "/" + report_name + ".arf\"" %}
{% endif %}

{% if cis_settings.openscap.oscap.verbose_log != '' %}
  {% set args = args + " --verbose " + cis_settings.openscap.oscap.verbose_level + " --verbose-log-file \"" + cis_settings.openscap.oscap.verbose_log + ".log\"" %}
{% endif %}

{% if profile != '' and benchmark != '' %}
{#
 # oscap returns 0 if all rules pass.
 # If there is an error during evaluation, the return code is 1.
 # If there is at least one rule with either fail or unknown result,
 # oscap-scan finishes with return code 2.
 #
 # cmd.run will consider itself failed with a return code of 2; hence run true|false based on $?
 #
 # oscap xccdf eval will also typically output some non-error related output to stderr, hence 2>&1
 #
 # NOTE: I know this is all dumb. We really need a custom execution module to handle running oscap... that's not the current one.
 #
 #}
{% set args = args + " --profile \"" + profile + "\" \"" + cis_settings.lookup.locations.openscap.oscap.benchmarks + "/" + benchmark + "\" 2>&1" %}
oscap_xccdf_eval:
  cmd.run:
    - name: oscap xccdf eval {{ args }} 2>&1 ; if [ ${?} -ne 1 ] ; then true ; else false ; fi
    - output_loglevel: quiet
    - hide_output: True

{% if cis_settings.audit.destination == 'master' %}

{% set upload_path = "/oscap/" + report_file %}
{% if cis_settings.audit.master.upload_path != '' %}
{% set upload_path = cis_settings.audit.master.upload_path + "/" + report_file %}
{% endif %}

oscap_report_push:
  module.run:
    - name: cp.push
    - path: {{ reports_dir }}/{{ report_file }}
    - upload_path: {{ upload_path }}

cis/audit/report/available:
  event.send:
    - data:
      filename: {{ upload_path }}
    - require:
      - module: oscap_report_push

{% if cis_settings.audit.s3.bucket != '' %}
s3_report_push:
  module.run:
    - name: s3_custom.put
    - kwargs:
      bucket: {{ cis_settings.audit.s3.bucket }}
      path: {{ report_file }}
      local_file: {{ reports_dir }}/{{ report_file }}
      headers:
        Content-Type: text/{{ cis_settings.audit.format }}
    - require:
      - event: cis/audit/report/available
{% endif %}

{% endif %}

{% endif %}

{# EOF #}
