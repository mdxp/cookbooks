#
# Author:: Marius Ducea (marius@promethost.com)
# Cookbook Name:: tomcat
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

require_recipe "java"

%w{ tomcat6 tomcat6-admin }.each do |pkg|
  package pkg
end

%w{libmysql-java libtcnative-1}.each do |pkg|
  package pkg
end

link "/usr/share/tomcat6/lib/mysql-connector-java.jar" do
    to "/usr/share/java/mysql-connector-java-5.1.10.jar"
end

service "tomcat6" do
  supports [ :status, :restart ]
end

template "/etc/default/tomcat6" do
  source "tomcat6.erb"
  owner "root"
  group "root"
  mode 0644
  notifies :restart, resources(:service => "tomcat6")
end

%w{server.xml tomcat-users.xml context.xml}.each do |conf|
  template "/etc/tomcat6/#{conf}" do
    source "#{conf}.erb"
    owner "#{node[:tomcat][:user]}"
    group "#{node[:tomcat][:group]}"
    mode 0644
    notifies :restart, resources(:service => "tomcat6")
  end
end

