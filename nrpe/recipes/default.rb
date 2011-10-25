package "nagios-nrpe-server"

service "nagios-nrpe-server" do
  action :enable
  supports :restart => true, :reload => true
end

template "/etc/nagios/nrpe.cfg" do
  source "nrpe.cfg.erb"
  variables(
    :ip => node["network"]["interfaces"]["#{node[:nrpe][:interface]}"]["addresses"].find {|addr, addr_info| addr_info[:family] == "inet"}.first
  )
  notifies :restart, resources(:service => "nagios-nrpe-server")
end

# This is needed for the check_logfiles plugin
package "libconfig-tiny-perl"

remote_directory "/etc/nagios/checklogs" do
  source "checklogs"
  purge false
  files_backup 5
  files_owner "nagios"
  files_group "nagios"
  files_mode 00644
  owner "nagios"
  group "nagios"
  mode 00755
end

directory "/usr/lib/nagios/tmp" do
  owner "nagios"
  group "nagios"
  mode 00755
  recursive true
end

# Various custom plugins
remote_directory node[:nrpe][:plugin_dir] do
  source "plugins"
  purge false
  files_backup 5
  files_owner "nagios"
  files_group "nagios"
  files_mode 00755
  #owner "nagios"
  #group "nagios"
  mode 00755
end
