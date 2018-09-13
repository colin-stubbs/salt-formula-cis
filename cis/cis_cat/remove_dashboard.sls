{% from "cis/map.jinja" import cis_settings with context %}

{% if 'cis_cat' in cis_settings and 'dashboard' in cis_settings.cis_cat %}
cis-cat-dashboard-install-dir:
  file.absent:
    - name: {{ cis_settings.lookup.locations.cis_cat.dashboard.install }}

{% if cis_settings.cis_cat.dashboard.tomcat.manage == True and cis_settings.cis_cat.dashboard.tomcat.use_system_package != True %}
cis-cat-tomcat-install-dir:
  file.absent:
    - name: {{ cis_settings.lookup.locations.tomcat.manual.install_dir }}

cis-cat-dashboard-service:
  service.dead:
    - name: cis-cat-dashboard.service

cis-cat-dashboard-service-file:
  file.absent:
    - name: /etc/systemd/system/cis-cat-tomcat.service
    - require:
      - service: cis-cat-dashboard-service

cis-cat-manual-tomcat-service-systemctl-reload:
  cmd.run:
    - name: systemctl daemon-reload
    - onchanges:
      - file: cis-cat-dashboard-service-file

{% endif %}
{% endif %}

{# EOF #}
