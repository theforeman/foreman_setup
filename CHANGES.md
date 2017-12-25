# Changelog

## v6.0.0
* fix Foreman 1.17 compatibility with Rails 5

## v5.0.1
* use case-insensitive OS family comparisons
* change Katello installer commands

## v5.0.0
* fix Foreman 1.13 compatibility with parameter filtering

## v4.0.0
* fix Foreman 1.12 compatibility with icons, CSS, template rendering etc.
* fix empty DHCP range in installer arguments if left blank
* remove Spacewalk functionality

## v3.1.1
* update DB migration limits for Rails 4.2 change
* fix Rails 4.2 routing deprecation
* fix Foreman 1.11 registration deprecation
* fix tests against develop, catch test errors

## v3.1.0
* add Catalan language, update translations
* fix compatibility with Rails 4 for Foreman 1.11
* add tests

## v3.0.2
* fix missing hyphens in installer arguments (#11399)

## v3.0.1
* remove dashboard button, use the menu instead
* remove unused deface dependency
* fix missing false.png image (#11115)

## v3.0.0
* show katello-installer commands if Katello is loaded
* fix Foreman 1.9 compatibility due to template changes
* this version (3.x) drops support for Foreman 1.8 and earlier

## v2.1.1
* fix kickstart template name for RHEL (#8452)

## v2.1.0
* i18n support (French and Spanish complete)

## v2.0.4
* use foreman_url from settings, not browser URL for installer base URL
* associate finish templates
* remove JavaScript assets (#12)

## v2.0.3
* fix Facter 2 compatibility

## v2.0.2
* remove obsolete menu extension, causing warnings

## v2.0.1
* add support for precompiling JavaScript assets

## v2.0.0
* add support for Foreman 1.5 auth system (#4538)
* this version (2.x) drops support for Foreman 1.4 and earlier
* update menu references for Foreman 1.4 (Jean-Baptiste Rouault)

## v1.0.4
* further Foreman 1.4 fixes, template renames and CSS

## v1.0.3
* fix Foreman 1.4 compatibility
* add basic role and permission under Foreman 1.4

## v1.0.2
* fix Ruby 1.8 compatibility (Yamakasi)

## v1.0.1
* fix architecture assignment in host group
* fix template search under PostgreSQL

## v1.0.0
* initial release
