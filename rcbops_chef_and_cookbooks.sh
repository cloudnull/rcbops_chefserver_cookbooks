#!/usr/bin/env bash
set -v

# Copyright [2013] [Kevin Carter]
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.


# This script will install several bits
# ============================================================================
# The Latest Stable Chef Server
# Chef Client
# Knife


# Here are the script Override Values.
# Any of these override variables can be exported as environment variables.
# ============================================================================
# Set this to override the chef default password, DEFAULT is "Random Things"
# CHEF_PW=""

# Set this to override the RabbitMQ Password, DEFAULT is "Random Things"
# RMQ_PW=""

# Set this to override the Cookbook version, DEFAULT is "v4.1.2"
# COOKBOOK_VERSION=""

# Begin the Install Process
# ============================================================================


# Make the system key used for bootstrapping self
yes '' | ssh-keygen -t rsa -f /root/.ssh/id_rsa -N ''
pushd /root/.ssh/
cat id_rsa.pub | tee -a authorized_keys
popd

# Upgrade packages and repo list.
apt-get update && apt-get -y upgrade
apt-get install -y rabbitmq-server git curl lvm2

# Chef Server Password
CHEF_PW=${CHEF_PW:-$(tr -dc 'a-zA-Z0-9' < /dev/urandom | head -c 9)}

# Set Rabbit Pass
RMQ_PW=${RMQ_PW:-$(tr -dc 'a-zA-Z0-9' < /dev/urandom | head -c 9)}

# Set Cookbook Version
CBV=${COOKBOOK_VERSION:-v4.1.2}

# Configure Rabbit
rabbitmqctl add_vhost /chef
rabbitmqctl add_user chef ${RMQ_PW}
rabbitmqctl set_permissions -p /chef chef '.*' '.*' '.*'

# Download/Install Chef
wget -O /tmp/chef_server.deb 'https://www.opscode.com/chef/download-server?p=ubuntu&pv=12.04&m=x86_64'
dpkg -i /tmp/chef_server.deb

# Configure Chef Vars
mkdir /etc/chef-server
cat > /etc/chef-server/chef-server.rb <<EOF
nginx["ssl_port"] = 4000
nginx["non_ssl_port"] = 4080
nginx["enable_non_ssl"] = true
rabbitmq["enable"] = false
rabbitmq["password"] = "${RMQ_PW}"
chef_server_webui['web_ui_admin_default_password'] = "${CHEF_PW}"
bookshelf['url'] = "https://#{node['ipaddress']}:4000"
EOF

# Reconfigure Chef
chef-server-ctl reconfigure

# Install Chef Client
bash <(wget -O - http://opscode.com/chef/install.sh)

# Configure Knife
mkdir /root/.chef
cat > /root/.chef/knife.rb <<EOF
log_level                :info
log_location             STDOUT
node_name                'admin'
client_key               '/etc/chef-server/admin.pem'
validation_client_name   'chef-validator'
validation_key           '/etc/chef-server/chef-validator.pem'
chef_server_url          'https://localhost:4000'
cache_options( :path => '/root/.chef/checksums' )
cookbook_path            [ '/opt/allinoneinone/chef-cookbooks/cookbooks' ]
EOF

# Get RcbOps Cookbooks
mkdir -p /opt/allinoneinone
git clone -b grizzly git://github.com/rcbops/chef-cookbooks.git /opt/allinoneinone/chef-cookbooks
pushd /opt/allinoneinone/chef-cookbooks
git submodule init
git checkout ${CBV}
git submodule update

# Get add-on Cookbooks
knife cookbook site download -f /tmp/cron.tar.gz cron 1.2.6 && tar xf /tmp/cron.tar.gz -C /opt/allinoneinone/chef-cookbooks/cookbooks

knife cookbook site download -f /tmp/chef-client.tar.gz chef-client 3.0.6 && tar xf /tmp/chef-client.tar.gz -C /opt/allinoneinone/chef-cookbooks/cookbooks

# Upload all of the RCBOPS Cookbooks
knife cookbook upload -o /opt/allinoneinone/chef-cookbooks/cookbooks -a

# Upload all of the RCBOPS Roles
knife role from file /opt/allinoneinone/chef-cookbooks/roles/*.rb

# Exit cookbook directory
popd

# Set the systems IP ADDRESS
SYS_IP=$(ohai ipaddress | awk '/^ / {gsub(/ *\"/, ""); print; exit}')

# go to root home
pushd /root
echo "export EDITOR=vim" | tee -a .bashrc
popd

# Remove MOTD files
rm /etc/motd
rm /var/run/motd

# Remove PAM motd modules from config
sed -i '/pam_motd.so/ s/^/#\ /' /etc/pam.d/login
sed -i '/pam_motd.so/ s/^/#\ /' /etc/pam.d/sshd

# Notify the users and set new the MOTD
echo -e "

** NOTICE **

Chef Server Creds and data.
# ============================================================================

Your RabbitMQ Password is      : ${RMQ_PW}
Chef Server HTTPS URL is       : https://${SYS_IP}:4000
Chef Server HTTP URL is        : https://${SYS_IP}:4080
Chef Server Password is        : ${CHEF_PW}
RCBOPS Cookbook Version        : ${CBV}
Your knife.rb is located       : /root/.chef/knife.rb
All cookbooks are located      : /opt/allinoneinone

# ============================================================================

" | tee /etc/motd

# Tell users how to get started on the CLI
echo -e "
You also have access to \"knife\" which can be used for modification and
management of your Chef Server.

"

# Exit Zero
exit 0
