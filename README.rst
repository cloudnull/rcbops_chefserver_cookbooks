Chef Server and Cookbooks
#########################
:date: 2013-09-05 09:51
:tags: rackspace, openstack, chef, chef-server
:category: \*nix

Create a Chef Server with RCBOPS Cookbooks in Minutes
=====================================================


General Overview
~~~~~~~~~~~~~~~~


This is a simple script to deploy a chef server and all of the RCBOPS cookbooks.


This script will install the following:

* RCBOPS Cookbooks
* The Latest Stable Chef Server
* Chef Client
* Knife


========


Configuration Options
~~~~~~~~~~~~~~~~~~~~~


The script has a bunch of override variables that can be set in script or as environment variables.


Set this to override the RCBOPS Developer Mode, DEFAULT is False:
  DEVELOPER_MODE=True or False

Set this to override the chef default password, DEFAULT is "Random Things":
  CHEF_PW=""

Set this to override the RabbitMQ Password, DEFAULT is "Random Things":
  RMQ_PW=""


========


Here is how you can get Started.
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~


1. Provision Server with a minimum of 2GB of ram and 10GB of hard disk space.
2. Login to server as root
3. Set any of your environment variables that you may want to use while running the script.
4. execute::

    curl https://raw.github.com/cloudnull/rcbops_chefserver_cookbooks/master/rcbops_chef_and_cookbooks.sh | bash


5. Go to the IP address of your server, login to chef, do work.


License:
  Copyright [2013] [Kevin Carter]

  Licensed under the Apache License, Version 2.0 (the "License");
  you may not use this file except in compliance with the License.
  You may obtain a copy of the License at
  http://www.apache.org/licenses/LICENSE-2.0

  Unless required by applicable law or agreed to in writing, software
  distributed under the License is distributed on an "AS IS" BASIS,
  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
  See the License for the specific language governing permissions and
  limitations under the License.
