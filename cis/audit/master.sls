{% from "cis/map.jinja" import cis_settings with context %}

{# do things on the master #}

{% set report_file = reports_dir + "/" + report_name + "." + report_extension %}

{% if cis_settings.audit.compress == True %}
{% if cis_settings.audit.compress_exec == 'bzip2' %}
compress_report:
  cmd.run:
    - name: bzip2 {{ report_file }}
{% set report_file = report_file + ".bz2" %}
{% else %}
{# assumes gzip at this time #}
compress_report:
  cmd.run:
    - name: gzip {{ report_file }}
{% set report_file = report_file + ".gz" %}
{% endif %}

{% if cis_settings.audit.hash == True %}
{% set report_file_hash = report_file + "." + cis_settings.audit.hash_exec %}
hash_report:
  cmd.run:
    - name: {{ cis_settings.cis_cat.assessor.local.hash_exec }} {{ report_file }} > {{ report_file_hash }}
{% endif %}
{% endif %}


{% if cis_settings.cis_cat.assessor.hash == True %}
cis_cat_report_push_hash:
  module.run:
    - name: cp.push
    - path: {{ report_file_hash }}
  {% if cis_settings.cis_cat.assessor.master.upload_path != '' %}
    - upload_path: {{ cis_settings.cis_cat.assessor.master.upload_path }}
  {% endif %}
  {% if cis_settings.cis_cat.assessor.master.remove_report_from_minion == True %}
    - remove_source: True
  {% endif %}
{% endif %}

{% elif cis_settings.audit.destination == 's3' %}
{% set put_filename = cis_settings.cis_cat.assessor.s3.path + report_name + "." + report_extension %}
cis_cat_report_s3:
  module.run:
    - name: s3_custom.put:
    - bucket: {{ cis_settings.cis_cat.assessor.s3.bucket }}
    - path: {{ put_filename }}
    {% for key, value in cis_settings.cis_cat.assessor.s3.args.items() %}
    - {{ key }}: {{ value }}
    {% endfor %}

{% if cis_settings.cis_cat.assessor.hash == True %}
cis_cat_report_push_hash:
  module.run:
    - name: cp.push
    - path: {{ report_file_hash }}
  {% if cis_settings.cis_cat.assessor.master.upload_path != '' %}
    - upload_path: {{ cis_settings.cis_cat.assessor.master.upload_path }}
  {% endif %}
  {% if cis_settings.cis_cat.assessor.master.remove_report_from_minion == True %}
    - remove_source: True
  {% endif %}
{% endif %}


{% elif cis_settings.audit.destination == 'curl' %}

{% set args = cis_settings.cis_cat.assessor.curl.args %}

{% for header in cis_settings.cis_cat.assessor.curl.headers.items %}
{% set args = args + " -H '{{ header }}'" %}
{% endfor %}

{% set args = args + " --data @{{ reports_dir }}/{{ report_name }}.{{ report_extension }}" %}

cis_cat_report_curl:
  cmd.run:
    - name: "curl {{ args }} {{  cis_settings.cis_cat.assessor.curl.url }}"

{% if cis_settings.cis_cat.assessor.curl.remove_report_from_minion == True %}
cis_cat_report_remove:
  file.absent:
    - name: {{ reports_dir }}/{{ report_name }}.{{ report_extension }}
    - require:
      - cmd: cis_cat_report_run
      - curl: cis_cat_report_curl
{% endif %}

{% if cis_settings.cis_cat.assessor.s3.remove_report_from_minion == True %}
cis_cat_report_remove:
  file.absent:
    - name: {{ reports_dir }}/{{ report_name }}.{{ report_extension }}
    - require:
      - cmd: cis_cat_report_run
      - module: cis_cat_report_s3
{% endif %}

{# EOF #}
