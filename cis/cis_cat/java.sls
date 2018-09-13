{% from "cis/map.jinja" import cis_settings with context %}

{# This is a hack that can be used to help get java onto systems that don't already have it #}

{% if grains.kernel == 'Linux' or grains.kernel == 'Windows' %}

{# ensure java is installed as we'll need it to run CIS-CAT and/or the Dashboard #}
cis-cat-requires-java:
  pkg.installed:
    - name: {{ cis_settings.lookup.pkgs.java }}

{% elif grains.os == 'MacOS' %}

{# need to download and install .dmg/.pkg from somewhere #}

{% if cis_settings.java.macos.pkg_version != '' and cis_settings.java.macos.pkg_source != '' and cis_settings.java.macos.pkg_hash != '' %}
download-java:
  file.managed:
    - name: '/tmp/java.pkg'
    - source: {{ cis_settings.java.macos.pkg_source }}
    {% if cis_settings.java.macos.pkg_hash != '' %}
    - source_hash: {{ cis_settings.java.macos.pkg_hash }}
    {% else %}
    - skip_verify: True
    {% endif %}
    - user: root
    - group: wheel
    - mode: 0644
    - unless:
      - 'java -version 2>&1 | grep -i "java version \"{{ cis_settings.java.macos.pkg_version }}\""'

install-java:
  macpackage.installed:
    - name: '/tmp/java.pkg'
    - target: /
    {# macpackage.installed behaves weirdly with version_check; version_check detects difference but fails to actually complete install. #}
    {# use force == True as workaround #}
    - force: True
    - version_check: 'java -version=.*java version "{{ cis_settings.java.macos.pkg_version }}".*'
    - require:
      - file: download-java

delete-java:
  file.absent:
    - name: '/tmp/java.pkg'
    - require:
      - file: download-java
      - macpackage: install-java
    - onlyif:
      - "test -f '/tmp/java.pkg'"

{% endif %}

{% endif %}

{# EOF #}


{# EOF #}
