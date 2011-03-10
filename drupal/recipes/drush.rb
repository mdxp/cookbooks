#
# Author:: Marius Ducea (marius@promethost.com)
# Cookbook Name:: drupal
# Recipe:: drush
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

include_recipe %w{php::php5 php::module_mysql}

remote_file "#{node[:drupal][:src]}/drush-All-versions-#{node[:drupal][:drush][:version]}.tar.gz" do
  checksum node[:drupal][:drush][:checksum]
  source "http://ftp.drupal.org/files/projects/drush-All-versions-#{node[:drupal][:drush][:version]}.tar.gz"
  mode "0644"
end

directory "#{node[:drupal][:drush][:dir]}" do
  owner "root"
  group "root"
  mode "0755"
  action :create
end

execute "untar-drush" do
  cwd node[:drupal][:drush][:dir]
  command "tar --strip-components 1 -xzf #{node[:drupal][:src]}/drush-All-versions-#{node[:drupal][:drush][:version]}.tar.gz"
  not_if "/usr/local/bin/drush status drush-version --pipe | grep #{node[:drupal][:drush][:version]}"
end

link "/usr/local/bin/drush" do
  to "#{node[:drupal][:drush][:dir]}/drush"
end

#execute "install-drush-make" do
#  cwd node[:drupal][:drush][:dir]
#  command "/usr/local/bin/drush dl drush_make"
#  not_if { File.directory?("/root/.drush/drush_make")}
#end
