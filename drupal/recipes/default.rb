#
# Author:: Marius Ducea (marius@promethost.com)
# Cookbook Name:: drupal
# Recipe:: default
#
# Copyright 2010, Promet Solutions
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
include_recipe %w{php::php5 php::module_mysql}
include_recipe "mysql::server"
Gem.clear_paths
require 'mysql'

execute "mysql-install-drupal-privileges" do
  command "/usr/bin/mysql -u root -p#{node[:mysql][:server_root_password]} < /etc/mysql/drupal-grants.sql"
  action :nothing
end

template "/etc/mysql/drupal-grants.sql" do
  path "/etc/mysql/drupal-grants.sql"
  source "grants.sql.erb"
  owner "root"
  group "root"
  mode "0600"
  variables(
    :user     => node[:drupal][:db][:user],
    :password => node[:drupal][:db][:password],
    :database => node[:drupal][:db][:database]
  )
  notifies :run, resources(:execute => "mysql-install-drupal-privileges"), :immediately
end

execute "create #{node[:drupal][:db][:database]} database" do
  command "/usr/bin/mysqladmin -u root -p#{node[:mysql][:server_root_password]} create #{node[:drupal][:db][:database]}"
  not_if do
    m = Mysql.new("localhost", "root", node[:mysql][:server_root_password])
    m.list_dbs.include?(node[:drupal][:db][:database])
  end
end

#install drupal
remote_file "#{node[:drupal][:src]}/drupal-#{node[:drupal][:version]}.tar.gz" do
  checksum node[:drupal][:checksum]
  source "http://ftp.drupal.org/files/projects/drupal-#{node[:drupal][:version]}.tar.gz"
  mode "0644"
end

directory "#{node[:drupal][:dir]}" do
  owner "root"
  group "root"
  mode "0755"
  action :create
end

execute "untar-drupal" do
  cwd node[:drupal][:dir]
  command "tar --strip-components 1 -xzf #{node[:drupal][:src]}/drupal-#{node[:drupal][:version]}.tar.gz"
  creates "#{node[:drupal][:dir]}/index.php"
end

if node.has_key?("ec2")
  server_fqdn = node.ec2.public_hostname
else
  server_fqdn = node.fqdn
end

log "Navigate to 'http://#{server_fqdn}/install.php' to complete the drupal installation" do
  action :nothing
end

directory "#{node[:drupal][:dir]}/sites/default/files" do
  mode "0777"
  action :create
end

template "#{node[:drupal][:dir]}/sites/default/settings.php" do
  source "settings.php.erb"
  mode "0644"
  variables(
    :database        => node[:drupal][:db][:database],
    :user            => node[:drupal][:db][:user],
    :password        => node[:drupal][:db][:password]
  )
  notifies :write, resources(:log => "Navigate to 'http://#{server_fqdn}/install.php' to complete the drupal installation")
end

web_app "drupal" do
  template "drupal.conf.erb"
  docroot "#{node[:drupal][:dir]}"
  server_name server_fqdn
  server_aliases node.fqdn
end

include_recipe "drupal::cron"
