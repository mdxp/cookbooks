#
# Author:: Marius Ducea (marius@promethost.com)
# Cookbook Name:: noatime
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

#node[:filesystem].keys.select { |k| k =~ /\A\/dev\// }.map do |d|
#    mount "#{node[:filesystem][d][:mount]}" do
#	device "#{d}"
#	fstype "#{node[:filesystem][d][:fs_type]}"
#	options node[:filesystem][d][:mount_options] << "noatime"
#	action [:enable]
#    end
#end

## Unfortunately the above method is not working as expected, so I'll have to use sed to modify fstab directly
## Note: it will not remount the filesystems and only change fstab.

bash "enable noatime" do
  code <<-EOH
    sed -i -e '/noatime\\|noauto\\|swap\\|proc\\|sysfs\\|tmpfs\\|devpts\\|nfs\\|^#/ !s/defaults\\|remount-ro/&,noatime/g' /etc/fstab
  EOH
  only_if "grep -v 'noatime\\|noauto\\|swap\\|proc\\|sysfs\\|tmpfs\\|devpts\\|nfs\\|^#' /etc/fstab"
end

