{% from "cis/map.jinja" import cis_settings with context %}

{# Deploy and manage CIS-CAT Pro Assessor installation #}

include:
  - cis.cis_cat.java

{% if 'cis_cat' in cis_settings and 'assessor' in cis_settings.cis_cat %}
{# ensure the base CIS-CAT directory is created/has correct permissions #}
cis-cat-assessor-install-dir:
  file.directory:
    - name: {{ cis_settings.lookup.locations.cis_cat.assessor.install }}
    - makedirs: True
{% if grains.kernel == 'Linux' or grains.os == 'MacOS' %}
    - mode: 0750
    - user: {{ cis_settings.lookup.users.owner }}
    - group: {{ cis_settings.lookup.users.group }}
{% endif %}

{# ensure the reports directory is created/has correct permissions #}
cis-cat-assessor-reports-dir:
  file.directory:
    - name: {{ cis_settings.lookup.locations.cis_cat.assessor.reports }}
    - makedirs: True
{% if grains.kernel == 'Linux' or grains.os == 'MacOS' %}
    - mode: 0750
    - user: {{ cis_settings.lookup.users.owner }}
    - group: {{ cis_settings.lookup.users.group }}
{% endif %}
    - require:
      - file: cis-cat-assessor-install-dir

{% if 'source' in cis_settings.cis_cat.assessor and cis_settings.cis_cat.assessor.source != '' %}
{# unpack CIS-CAT Assessor tool onto the minion #}
cis-cat-assessor-extract:
  archive.extracted:
    - name: {{ cis_settings.lookup.locations.cis_cat.assessor.install }}
    - source: {{ cis_settings.cis_cat.assessor.source }}
{% if 'source_hash' in cis_settings.cis_cat.assessor and cis_settings.cis_cat.assessor.source_hash != '' %}
    - source_hash: {{ cis_settings.cis_cat.assessor.source_hash }}
    - source_hash_update: False
{% else %}
    - skip_verify: True
{% endif %}
{% if 'source_options' in cis_settings.cis_cat.assessor and cis_settings.cis_cat.assessor.source_options != '' %}
    - options: {{ cis_settings.cis_cat.assessor.source_options }}
{% endif %}
{% if 'enforce_toplevel' in cis_settings.cis_cat.assessor and cis_settings.cis_cat.assessor.enforce_toplevel == False %}
    - enforce_toplevel: False
{% endif %}
{% if grains.kernel == 'Windows' %}
{# clean really needs to be false on windows or file.recurse performance is horrible #}
    - clean: False
{% else %}
    - clean: True
{% endif %}
{% if grains.kernel == 'Linux' or grains.os == 'MacOS' %}
    - user: {{ cis_settings.lookup.users.owner }}
    - group: {{ cis_settings.lookup.users.group }}
{% endif %}
    - require:
      - file: cis-cat-assessor-install-dir
      - file: cis-cat-assessor-reports-dir
{% endif %}

{% if 'schedule' in cis_settings.cis_cat.assessor %}
{# ensure a schedule exists to run #}
cis-report-schedule:
  schedule.present:
{% for name, value in cis_settings.cis_cat.assessor.schedule.items() %}
    - {{ name }}: {{ value }}
{% endfor %}
    - function: state.apply
    - job_args: cis.cis_cat.audit
{% endif %}

{% endif %}

{# EOF #}
