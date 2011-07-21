#
# Author:: Marius Ducea (marius@promethost.com)
# Cookbook Name:: icinga
# Recipe:: core_source
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

# Install required packages
include_recipe "build-essential"

%w{ libgd2-xpm-dev libjpeg62-dev libpng12-dev libdbi0-dev snmp libsnmp-dev }.each do |pkg|
   package pkg
end

version = node['icinga']['version']
iuser = node['icinga']['user']
igroup = node['icinga']['group']

# Download icinga core source
remote_file "#{Chef::Config[:file_cache_path]}/icinga-#{version}.tar.gz" do
  source "http://downloads.sourceforge.net/project/icinga/icinga/#{version}/icinga-#{version}.tar.gz"
  checksum node['icinga']['checksum']
  action :create_if_missing
end

# icinga user/groups
user "#{iuser}" do
  comment "Icinga user"
  shell "/bin/false"
end
group "#{igroup}" do
   members [ iuser, node['apache']['user'] ]
end

# Compile & install icinga
bash "compile-install-icinga" do
  cwd Chef::Config[:file_cache_path]
  user "root"
  code <<-EOH
    tar -zxf icinga-#{version}.tar.gz && \
    cd icinga-#{version} && \
    ./configure --with-icinga-user=#{iuser} --with-icinga-group=#{igroup} --with-nagios-user=#{iuser} --with-nagios-group=#{igroup} \
    --with-command-user=#{iuser} --with-command-group=#{igroup} --prefix #{node['icinga']['prefix']} --enable-idoutils --enable-ssl && \
    make all && \
    make fullinstall
  EOH
  creates "#{node['icinga']['prefix']}/bin/icinga"
end

directory "#{node['icinga']['config_dir']}" do
  owner node['icinga']['user']
  group node['icinga']['group']
  mode "0755"
end

%w{ icinga cgi resource }.each do |conf|
  icinga_conf conf do
    config_subdir false
  end
end

%w{ commands templates timeperiods}.each do |conf|
  icinga_conf conf
end

