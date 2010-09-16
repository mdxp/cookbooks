#
# Author:: Marius Ducea (marius@promethost.com)
# Cookbook Name:: diaspora
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

include_recipe "build-essential"
include_recipe "xml"
include_recipe "imagemagick"
include_recipe "git"
include_recipe "mongodb-debs"

gem_package "bundler"
package "libxslt1-dev"

diaspora_dir = "#{node[:diaspora][:dir]}/diaspora"
execute "clone diaspora repository" do
  command "git clone http://github.com/diaspora/diaspora.git"
  cwd "#{node[:diaspora][:dir]}"
  not_if "test -d #{diaspora_dir}"
end

execute "bundle install" do
  command "bundle install"
  cwd "#{diaspora_dir}"
  not_if "cd #{diaspora_dir}; bundle check |grep 'dependencies are satisfied'"
end
