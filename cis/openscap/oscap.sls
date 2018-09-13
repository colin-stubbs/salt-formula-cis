{% from "cis/map.jinja" import cis_settings with context %}

{# Deploy and manage OpenSCAP installation #}

{% if grains.kernel == 'Linux' %}
openscap_scanner:
  pkg.installed:
    - name: {{ cis_settings.lookup.pkgs.openscap_scanner }}

openscap_scanner_reports:
  file.directory:
    - name: {{ cis_settings.lookup.locations.openscap.oscap.reports }}
    - user: root
    - group: root
    - mode: 0700
    - require:
      - pkg: openscap_scanner

scap_security_guide:
  pkg.installed:
    - name: {{ cis_settings.lookup.pkgs.scap_security_guide }}
{% endif %}

{# EOF #}
