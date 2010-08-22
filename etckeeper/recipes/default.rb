#
# Cookbook Name:: etckeeper
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

include_recipe "git"

return unless ["ubuntu", "debian"].include?(node[:platform])

package "etckeeper"

cookbook_file "/etc/etckeeper/etckeeper.conf" do
    source "etckeeper.conf"
    mode 0644
end

#Initialize the etckeeper repo for /etc
script "init_etckeeper" do
    interpreter "bash"
    user "root"
    code <<-EOH
	etckeeper init
	cd /etc
	git commit -a -m "initial import"
    EOH
    not_if "test -d /etc/.git"
end
