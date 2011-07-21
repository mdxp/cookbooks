#
# Author:: Marius Ducea (marius@promethost.com)
# Cookbook Name:: icinga
# Recipe:: server
#
# Copyright 2010-2011, Promet Solutions
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
#

include_recipe "apache2"
include_recipe "apache2::mod_ssl"
include_recipe "apache2::mod_rewrite"
include_recipe "icinga::plugins_package"
include_recipe "icinga::core_source"

sysadmins = search(:users, "groups:#{node['icinga']['sysadmin']}")
nodes = search(:node, "hostname:[* TO *] AND chef_environment:#{node.chef_environment}")

if nodes.empty?
  Chef::Log.info("No nodes returned from search, using this node so hosts.cfg has data")
  nodes = Array.new
  nodes << node
end

members = Array.new
sysadmins.each do |s|
  members << s['id']
end

role_list = Array.new
service_hosts= Hash.new
search(:role, "*:*") do |r|
  role_list << r.name
  search(:node, "role:#{r.name} AND chef_environment:#{node.chef_environment}") do |n|
    service_hosts[r.name] = n['hostname']
  end
end

if node['public_domain']
  public_domain = node['public_domain']
else
  public_domain = node['domain']
end

template "#{node['icinga']['conf_dir']}/htpasswd.users" do
  source "htpasswd.users.erb"
  owner node['icinga']['user']
  group node['apache']['user']
  mode 0640
  variables(
    :sysadmins => sysadmins
  )
end

apache_site "000-default" do
  enable false
end

template "#{node['apache']['dir']}/sites-available/icinga.conf" do
  source "apache2.conf.erb"
  mode 0644
  variables :public_domain => public_domain
  if ::File.symlink?("#{node['apache']['dir']}/sites-enabled/icinga.conf")
    notifies :reload, "service[apache2]"
  end
end

apache_site "icinga.conf"

icinga_conf "services" do
  variables :service_hosts => service_hosts
end

icinga_conf "contacts" do
  variables :admins => sysadmins, :members => members
end

icinga_conf "hostgroups" do
  variables :roles => role_list
end

icinga_conf "hosts" do
  variables :nodes => nodes
end

service "icinga" do
  supports :status => true, :restart => true, :reload => true
  action [ :enable, :start ]
end

