#
# Author:: Marius Ducea (marius@promethost.com)
# Cookbook Name:: s3sync
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

aws = data_bag_item("aws", "main")

gem_package "s3sync"

directory "/etc/s3conf" do
    mode 0750
    owner "root"
    group "root"
end

template "/etc/s3conf/s3config.yml" do
    source "s3config.yml.erb"
    mode 0640
    variables( :key_id => aws['aws_access_key_id'],
             :access_key => aws['aws_secret_access_key'])
end
