#
# Cookbook Name:: tomcat
# Attributes:: tomcat
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

default[:tomcat][:user] = "tomcat6"
default[:tomcat][:group] = "tomcat6"
default[:tomcat][:java_home] = "/usr/lib/jvm/java-6-openjdk"
default[:tomcat][:java_opts] = "-Djava.awt.headless=true -Xmx128M"
default[:tomcat][:security] = "no"
