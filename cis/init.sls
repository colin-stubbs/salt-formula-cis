{% from "cis/map.jinja" import cis_settings with context %}

{# Ensures all foundational components are installed to enable automation of auditing, reporting and remediation #}

include:
{% if cis_settings.audit.tool == 'cis-cat' or cis_settings.audit.tool == 'cis_cat' or grains.kernel != 'Linux' %}
  - cis.cis_cat.assessor
{% else %}
  - cis.openscap.oscap
{% endif %}

{# EOF #}
