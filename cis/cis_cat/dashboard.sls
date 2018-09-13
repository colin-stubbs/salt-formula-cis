{% from "cis/map.jinja" import cis_settings with context %}

{# Deploy and manage CIS-CAT Pro Dashboard installation #}

include:
  - cis.cis_cat.java

{% if 'cis_cat' in cis_settings and 'dashboard' in cis_settings.cis_cat %}
{# ensure the CIS-CAT Pro Dashboard install directory is created/has correct permissions #}
cis-cat-dashboard-install-dir:
  file.directory:
    - name: {{ cis_settings.lookup.locations.cis_cat.dashboard.install }}
    - makedirs: True
{% if grains.kernel == 'Linux' or grains.os == 'MacOS' %}
    - file_mode: 0640
    - dir_mode: 0750
    - user: {{ cis_settings.lookup.users.owner }}
    - group: {{ cis_settings.lookup.tomcat.group }}
    - recurse:
      - user
      - group
      - mode
{% endif %}

{# ensure the CIS-CAT Pro Dashboard logs directory is created/has correct permissions #}
cis-cat-dashboard-logs-dir:
  file.directory:
    - name: {{ cis_settings.lookup.locations.cis_cat.dashboard.logs }}
    - makedirs: True
{% if grains.kernel == 'Linux' or grains.os == 'MacOS' %}
    - file_mode: 0660
    - dir_mode: 0770
    - user: {{ cis_settings.lookup.tomcat.user }}
    - group: {{ cis_settings.lookup.tomcat.group }}
    - recurse:
      - user
      - group
      - mode
{% endif %}

{# ensure the legacy dirs for report ingestion are created #}
cis-cat-dashboard-legacy-sourceDir:
  file.directory:
    - name: {{ cis_settings.lookup.locations.cis_cat.dashboard.legacy }}/source
    - makedirs: True
{% if grains.kernel == 'Linux' or grains.os == 'MacOS' %}
    - mode: 0770
    - user: {{ cis_settings.lookup.tomcat.user }}
    - group: {{ cis_settings.lookup.tomcat.group }}
{% endif %}

{# ensure the legacy dirs for report ingestion are created #}
cis-cat-dashboard-legacy-processedDir:
  file.directory:
    - name: {{ cis_settings.lookup.locations.cis_cat.dashboard.legacy }}/processed
    - makedirs: True
{% if grains.kernel == 'Linux' or grains.os == 'MacOS' %}
    - mode: 0770
    - user: {{ cis_settings.lookup.tomcat.user }}
    - group: {{ cis_settings.lookup.tomcat.group }}
{% endif %}

{# ensure the legacy dirs for report ingestion are created #}
cis-cat-dashboard-legacy-errorDir:
  file.directory:
    - name: {{ cis_settings.lookup.locations.cis_cat.dashboard.legacy }}/error
    - makedirs: True
{% if grains.kernel == 'Linux' or grains.os == 'MacOS' %}
    - mode: 0770
    - user: {{ cis_settings.lookup.tomcat.user }}
    - group: {{ cis_settings.lookup.tomcat.group }}
{% endif %}

{% if 'source' in cis_settings.cis_cat.dashboard and cis_settings.cis_cat.dashboard.source != '' %}
{# unpack dashboard package onto minion #}
cis-cat-dashboard-extract:
  archive.extracted:
    - name: {{ cis_settings.lookup.locations.cis_cat.dashboard.install }}
    - source: {{ cis_settings.cis_cat.dashboard.source }}
{% if 'source_hash' in cis_settings.cis_cat.dashboard and cis_settings.cis_cat.dashboard.source_hash != '' %}
    - source_hash: {{ cis_settings.cis_cat.dashboard.source_hash }}
    - source_hash_update: False
{% else %}
    - skip_verify: True
{% endif %}
{% if 'source_extract_options' in cis_settings.cis_cat.dashboard and cis_settings.cis_cat.dashboard.source_extract_options != '' %}
    - options: {{ cis_settings.cis_cat.dashboard.source_extract_options }}
{% endif %}
{% if 'enforce_toplevel' in cis_settings.cis_cat.dashboard and cis_settings.cis_cat.dashboard.enforce_toplevel == False %}
    - enforce_toplevel: False
{% endif %}
{% if grains.kernel == 'Windows' %}
{# clean really needs to be false on windows or file.recurse performance is horrible #}
    - clean: False
{% else %}
    - clean: True
{% endif %}
    - if_missing: {{ cis_settings.lookup.locations.cis_cat.dashboard.install }}/CCPD.war
    - require:
      - file: cis-cat-dashboard-install-dir
      - file: cis-cat-dashboard-logs-dir
{% endif %}

cis-cat-ccpd-config-yml:
  file.managed:
    - name: {{ cis_settings.lookup.locations.cis_cat.dashboard.ccpd_config_yml }}
    - source: salt://cis/files/ccpd-config.yml
    - template: jinja
    - context:
      config: {{ cis_settings.cis_cat.dashboard.config }}
{% if grains.kernel == 'Linux' or grains.os == 'MacOS' %}
    - mode: 0640
    - user: {{ cis_settings.lookup.users.owner }}
    - group: {{ cis_settings.lookup.tomcat.group }}
{% endif %}
{% if 'source' in cis_settings.cis_cat.dashboard and cis_settings.cis_cat.dashboard.source != '' %}
    - require:
      - archive: cis-cat-dashboard-extract
{% endif %}

{# MySQL/MariaDB #}
{% if cis_settings.cis_cat.dashboard.mysqld.manage == True %}
{% if cis_settings.cis_cat.dashboard.mysqld.admin_user != '' and cis_settings.cis_cat.dashboard.mysqld.admin_password != '' %}
{# TODO - create/manage ccpd user ? #}
{% endif %}
{% endif %}

{# Apache Tomcat #}
{% if cis_settings.cis_cat.dashboard.tomcat.manage == True %}
{# ensure Apache Tomcat is installed as we'll need it to run CIS-CAT Pro Dashboard #}

{% if cis_settings.cis_cat.dashboard.tomcat.use_system_package == True %}

{% set tomcat_service_name = cis_settings.lookup.tomcat.service %}
{% set tomcat_config_dir = cis_settings.lookup.locations.tomcat.system.config_dir %}
{% set tomcat_webapps_dir = cis_settings.lookup.locations.tomcat.system.webapps_dir %}
{% set tomcat_server_xml = cis_settings.lookup.locations.tomcat.system.config_dir + '/server.xml' %}
{% set tomcat_context_xml = cis_settings.lookup.locations.tomcat.system.config_dir + '/context.xml' %}
{% set tomcat_env_variables = cis_settings.lookup.locations.tomcat.system.config_dir + '/conf.d/ccpd.conf' %}

cis-cat-requires-tomcat:
  pkg.installed:
    - name: {{ cis_settings.lookup.pkgs.tomcat }}
    - require_in:
      - service: cis-cat-requires-tomcat-running
    - watch_in:
      - service: cis-cat-requires-tomcat-running

{% else %} {# install manually #}

{% set tomcat_service_name = '' %} {# FIX ME #}
{% set tomcat_config_dir = cis_settings.lookup.locations.tomcat.manual.install_dir + '/conf' %}
{% set tomcat_webapps_dir = cis_settings.lookup.locations.tomcat.manual.install_dir + '/webapps' %}
{% set tomcat_server_xml = tomcat_config_dir + '/server.xml' %}
{% set tomcat_context_xml = tomcat_config_dir + '/context.xml' %}
{% set tomcat_env_variables = cis_settings.lookup.locations.tomcat.manual.install_dir + '/bin/setenv.sh' %}

{# ensure the CIS-CAT Pro Dashboard install directory is created/has correct permissions #}
cis-cat-tomcat-install-dir:
  file.directory:
    - name: {{ cis_settings.lookup.locations.tomcat.manual.install_dir }}
    - makedirs: True
{% if grains.kernel == 'Linux' or grains.os == 'MacOS' %}
    - mode: 0750
    - user: {{ cis_settings.lookup.users.owner }}
    - group: {{ cis_settings.lookup.tomcat.group }}
{% endif %}

{# download and unpack tomcat archive onto minion #}
cis-cat-apache-tomcat-extract:
  archive.extracted:
    - name: {{ cis_settings.lookup.locations.tomcat.manual.install_dir }}
    - source: {{ cis_settings.cis_cat.tomcat.source }}
{% if 'source_hash' in cis_settings.cis_cat.tomcat and cis_settings.cis_cat.tomcat.source_hash != '' %}
    - source_hash: {{ cis_settings.cis_cat.tomcat.source_hash }}
    - source_hash_update: False
{% else %}
    - skip_verify: True
{% endif %}
{% if 'source_extract_options' in cis_settings.cis_cat.tomcat and cis_settings.cis_cat.tomcat.source_extract_options != '' %}
    - options: {{ cis_settings.cis_cat.tomcat.source_extract_options }}
{% endif %}
{% if 'enforce_toplevel' in cis_settings.cis_cat.tomcat and cis_settings.cis_cat.tomcat.enforce_toplevel == False %}
    - enforce_toplevel: False
{% endif %}
{% if grains.kernel == 'Windows' %}
{# clean really needs to be false on windows or file.recurse performance is horrible #}
    - clean: False
{% else %}
    - clean: True
{% endif %}
    - if_missing: {{ cis_settings.lookup.locations.tomcat.manual.install_dir }}/bin/catalina.sh
    - require:
      - file: cis-cat-tomcat-install-dir

cis-cat-apache-tomcat-extract-top-perms:
  file.directory:
    - name: {{ cis_settings.lookup.locations.tomcat.manual.install_dir }}
    - user: {{ cis_settings.lookup.users.owner }}
    - group: {{ cis_settings.lookup.tomcat.group }}
    - file_mode: 0644
    - dir_mode: 0755
    - recurse:
      - user
      - group
      - mode
    - require:
      - archive: cis-cat-apache-tomcat-extract
    - onchanges:
      - archive: cis-cat-apache-tomcat-extract

cis-cat-apache-tomcat-extract-webapps-perms:
  file.directory:
    - name: {{ cis_settings.lookup.locations.tomcat.manual.install_dir }}/webapps
    - user: {{ cis_settings.lookup.tomcat.user }}
    - group: {{ cis_settings.lookup.tomcat.group }}
    - mode: 0770
    - require:
      - file: cis-cat-apache-tomcat-extract-top-perms

cis-cat-apache-tomcat-extract-logs-perms:
  file.directory:
    - name: {{ cis_settings.lookup.locations.tomcat.manual.install_dir }}/logs
    - user: {{ cis_settings.lookup.tomcat.user }}
    - group: {{ cis_settings.lookup.tomcat.group }}
    - mode: 0770
    - recurse:
      - user
      - group
    - require:
      - file: cis-cat-apache-tomcat-extract-top-perms

cis-cat-apache-tomcat-extract-temp-perms:
  file.directory:
    - name: {{ cis_settings.lookup.locations.tomcat.manual.install_dir }}/temp
    - user: {{ cis_settings.lookup.tomcat.user }}
    - group: {{ cis_settings.lookup.tomcat.group }}
    - mode: 0770
    - recurse:
      - user
      - group
    - require:
      - file: cis-cat-apache-tomcat-extract-top-perms

cis-cat-apache-tomcat-extract-work-perms:
  file.directory:
    - name: {{ cis_settings.lookup.locations.tomcat.manual.install_dir }}/work
    - user: {{ cis_settings.lookup.tomcat.user }}
    - group: {{ cis_settings.lookup.tomcat.group }}
    - mode: 0770
    - recurse:
      - user
      - group
    - require:
      - file: cis-cat-apache-tomcat-extract-top-perms

cis-cat-apache-tomcat-extract-bin-perms:
  file.directory:
    - name: {{ cis_settings.lookup.locations.tomcat.manual.install_dir }}/bin
    - user: {{ cis_settings.lookup.users.owner }}
    - group: {{ cis_settings.lookup.tomcat.group }}
    - dir_mode: 750
    - file_mode: 750
    - recurse:
      - user
      - group
      - mode
    - require:
      - file: cis-cat-apache-tomcat-extract-top-perms

{# clean default crap out of the webapps directory #}
cis-cat-tomcat-clean-default-webapps:
  cmd.run:
    - name: rm -rf {{ tomcat_webapps_dir }}/docs {{ tomcat_webapps_dir }}/examples {{ tomcat_webapps_dir }}/host-manager {{ tomcat_webapps_dir }}/manager {{ tomcat_webapps_dir }}/ROOT
    - onlyif:
      - test -d {{ tomcat_webapps_dir }}/examples

{# install system service file #}
cis-cat-manual-tomcat-service-file:
  file.managed:
    - name: /etc/systemd/system/cis-cat-tomcat.service
    - source: salt://cis/files/tomcat.service
    - template: jinja
    - context:
      tomcat_root: {{ cis_settings.lookup.locations.tomcat.manual.install_dir }}
    - user: root
    - group: root
    - mode: 0644
    - require:
      - archive: cis-cat-apache-tomcat-extract
      - cmd: cis-cat-tomcat-clean-default-webapps
      - file: cis-cat-apache-tomcat-extract-webapps-perms
      - file: cis-cat-apache-tomcat-extract-logs-perms
      - file: cis-cat-apache-tomcat-extract-temp-perms
      - file: cis-cat-apache-tomcat-extract-work-perms
      - file: cis-cat-apache-tomcat-extract-bin-perms
    - require_in:
      - service: cis-cat-requires-tomcat-running
    - watch_in:
      - service: cis-cat-requires-tomcat-running

{% set tomcat_service_name = 'cis-cat-tomcat.service' %}

cis-cat-manual-tomcat-service-systemctl-reload:
  cmd.run:
    - name: systemctl daemon-reload
    - onchanges:
      - file: cis-cat-manual-tomcat-service-file

{# create group #}
cis-cat-tomcat-group:
  group.present:
    - name: {{ cis_settings.lookup.tomcat.user }}
    - gid: {{ cis_settings.lookup.tomcat.gid }}

{# create user #}
cis-cat-tomcat-user:
  user.present:
    - name: {{ cis_settings.lookup.tomcat.group }}
    - uid: {{ cis_settings.lookup.tomcat.uid }}
    - gid: {{ cis_settings.lookup.tomcat.gid }}
    - home: {{ cis_settings.lookup.tomcat.home|default(cis_settings.lookup.locations.tomcat.manual.install_dir) }}
    - shell: {{ cis_settings.lookup.tomcat.shell|default('/bin/bash') }}
    - require:
      - group: cis-cat-tomcat-group
    - require_in:
      - service: cis-cat-requires-tomcat-running
    - watch_in:
      - service: cis-cat-requires-tomcat-running

{% endif %} {# manual tomcat config #}

{# sym link CCPD.war into Tomcat webapps directory #}
{% if tomcat_webapps_dir != '' %}
cis-cat-symlink-ccpd-war:
  file.symlink:
    - name: {{ tomcat_webapps_dir }}/CCPD.war
    - target: {{ cis_settings.lookup.locations.cis_cat.dashboard.install }}/CCPD.war
    - user: {{ cis_settings.lookup.tomcat.user }}
    - group: {{ cis_settings.lookup.tomcat.group }}
    - require:
{% if cis_settings.cis_cat.dashboard.tomcat.use_system_package == True %}
      - pkg: cis-cat-requires-tomcat
{% else %}
      - archive: cis-cat-apache-tomcat-extract
{% endif %}
{% endif %}

{# configure Tomcat #}
cis-cat-tomcat-server-xml:
  file.managed:
    - name: {{ tomcat_server_xml }}
    - template: jinja
    - source: salt://cis/files/server.xml
    - user: {{ cis_settings.lookup.users.owner }}
    - group: {{ cis_settings.lookup.tomcat.group }}
    - require:
{% if cis_settings.cis_cat.dashboard.tomcat.use_system_package == True %}
      - pkg: cis-cat-requires-tomcat
{% else %}
      - archive: cis-cat-apache-tomcat-extract
{% endif %}

cis-cat-tomcat-context-xml:
  file.managed:
    - name: {{ tomcat_context_xml }}
    - template: jinja
    - context:
      cache_size: {{ cis_settings.cis_cat.dashboard.tomcat.cache_size }}
    - source: salt://cis/files/context.xml
    - user: {{ cis_settings.lookup.users.owner }}
    - group: {{ cis_settings.lookup.tomcat.group }}
    - require:
{% if cis_settings.cis_cat.dashboard.tomcat.use_system_package == True %}
      - pkg: cis-cat-requires-tomcat
{% else %}
      - archive: cis-cat-apache-tomcat-extract
{% endif %}

{# CCPD environment variables #}
cis-cat-tomcat-server-variables:
  file.managed:
    - name: {{ tomcat_env_variables }}
    - template: jinja
    - source: salt://cis/files/env.sh
    - user: {{ cis_settings.lookup.users.owner }}
    - group: {{ cis_settings.lookup.tomcat.group }}
    - mode: 0750
    - context:
      ccpd_config_yml: {{ cis_settings.lookup.locations.cis_cat.dashboard.ccpd_config_yml }}
      log_dir: {{ cis_settings.lookup.locations.cis_cat.dashboard.logs }}
      dashboard_catalina_opts: {{ cis_settings.cis_cat.dashboard.java_args }}
    - require:
{% if cis_settings.cis_cat.dashboard.tomcat.use_system_package == True %}
      - pkg: cis-cat-requires-tomcat
{% else %}
      - archive: cis-cat-apache-tomcat-extract
{% endif %}

{% if tomcat_service_name != '' %}
{# ensure tomcat service is running #}
cis-cat-requires-tomcat-running:
  service.running:
    - name: {{ tomcat_service_name }}
    - enable: True
    - require:
      - file: cis-cat-tomcat-server-xml
      - file: cis-cat-tomcat-context-xml
      - file: cis-cat-tomcat-server-variables
      - file: cis-cat-symlink-ccpd-war
      - file: cis-cat-ccpd-config-yml
      - file: cis-cat-dashboard-legacy-sourceDir
      - file: cis-cat-dashboard-legacy-processedDir
      - file: cis-cat-dashboard-legacy-errorDir
    - watch:
      - file: cis-cat-tomcat-server-xml
      - file: cis-cat-tomcat-context-xml
      - file: cis-cat-tomcat-server-variables
      - file: cis-cat-symlink-ccpd-war
{% endif %}

{% endif %} {# if cis_settings.cis_cat.dashboard.tomcat.manage == True #}
{% endif %} {# if 'cis_cat' in cis_settings and 'dashboard' in cis_settings.cis_cat #}

{# EOF #}
