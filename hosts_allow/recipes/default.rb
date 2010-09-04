#
# Author:: Marius Ducea (marius@promethost.com)
# Cookbook Name:: hosts_allow
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

template "/etc/hosts.allow" do
  source "hosts.allow.erb"
  owner "root"
  group "root"
  mode 0644
end

services = Array.new
if node[:hosts_allow]
  node[:hosts_allow].each_key do |key|
    node[:hosts_allow]["#{key}"].each do |service,ips|
      services << service
    end
  end
end

template "/etc/hosts.deny" do
  source "hosts.deny.erb"
  owner "root"
  group "root"
  mode 0644
  variables(
    :services => services.uniq
  )
end
