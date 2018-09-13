{% from "cis/map.jinja" import cis_settings with context %}

{# Abstraction layer to CIS-CAT Pro or OpenSCAP for auditing #}

{# TODO: based on cis_settings.audit.scheduler use alternate scheduling methods ? #}

audit_schedule:
  schedule.absent: []

{# EOF #}
