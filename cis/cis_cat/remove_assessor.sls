{% from "cis/map.jinja" import cis_settings with context %}

{% if 'cis_cat' in cis_settings and 'assessor' in cis_settings.cis_cat %}
cis-cat-assessor-install-dir:
  file.absent:
    - name: {{ cis_settings.lookup.locations.cis_cat.assessor.install }}

cis-cat-assessor-reports-dir:
  file.absent:
    - name: {{ cis_settings.lookup.locations.cis_cat.assessor.reports }}

cis-cat-report-schedule:
  schedule.absent:
    - name: cis-cat-report-schedule
{% endif %}

{# EOF #}
