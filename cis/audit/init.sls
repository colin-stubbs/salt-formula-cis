{% from "cis/map.jinja" import cis_settings with context %}

{# Abstraction layer to CIS-CAT Pro or OpenSCAP for auditing #}

include:
  - cis.{{ cis_settings.audit.tool }}.audit

{# EOF #}
