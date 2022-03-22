# foreman_setup

Setting up Foreman for provisioning can be daunting at first, as there are
lots of parameters to configure DHCP and DNS for the installer, plus for setup
of subnets, domains, installation media etc for Foreman.

# Installation

Please see the Foreman wiki for appropriate instructions:

* [Foreman: How to Install a Plugin](http://projects.theforeman.org/projects/foreman/wiki/How_to_Install_a_Plugin)

The gem name is "foreman_setup".  Run `foreman-rake db:migrate` after
installation.

RPM users can install the "tfm-rubygem-foreman_setup" or
"rubygem-foreman_setup" packages.

## Compatibility

| Foreman Version | Plugin Version |
| --------------- | --------------:|
| <= 1.4          | ~> 1.0         |
| >= 1.5          | ~> 2.0         |
| >= 1.9          | ~> 3.0         |
| >= 1.12         | ~> 4.0         |
| >= 1.13         | ~> 5.0         |
| >= 1.17         | ~> 6.0         |
| >= 1.22         | ~> 7.0         |
| >= 3.2          | ~> 8.0         |

# Areas this should help

* take input of subnet and domain information
* output foreman-installer command with appropriate DHCP, DNS and TFTP parameters
* add foreman-installer modules to the Foreman host with appropriate parameters
* create a host group with appropriate parameters
* create hosts (proxies/nodes) using created host groups
* ensure provided templates and OSes are fully associated
  * default templates should be properly associated in core
  * when using Katello, its Foreman plugin helps associate
* add appropriate installation media
* add appropriate Spacewalk/redhat_register parameters

# Copyright

Copyright (c) 2013 Red Hat Inc.

This program is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program.  If not, see <http://www.gnu.org/licenses/>.
