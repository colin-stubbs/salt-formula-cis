{% from "cis/map.jinja" import cis_settings with context %}

{# Abstraction layer to CIS-CAT Pro or OpenSCAP for auditing #}

{# TODO: based on cis_settings.audit.scheduler use alternate scheduling methods ? #}

audit_schedule:
  schedule.present:
    - function: state.sls
    - job_args:
      - cis.audit
    {% for key, value in cis_settings.audit.schedule.items() %}
    - {{ key }}: {{ value }}
    {% endfor %}

{# EOF #}
