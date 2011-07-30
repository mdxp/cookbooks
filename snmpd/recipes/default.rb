package "snmp"
package "snmpd"

template "/etc/snmp/snmpd.conf" do
  source "snmpd.conf.erb"
  owner "root"
  group "root"
  mode "0644"
  variables(
    :monitoring_ips => [node[:snmpd][:monitoring_ips]].flatten,
    :community => node[:snmpd][:community],
    :syslocation => node[:snmpd][:syslocation],
    :syscontact => node[:snmpd][:syscontact],
    :execs => [node[:snmpd][:execs]].flatten,
    :disks => [node[:snmpd][:disks]].flatten
  )
end

template "/etc/default/snmpd" do
  source "snmpd.default.erb"
  owner "root"
  group "root"
  mode "0644"
  variables(
    :ip => node["network"]["interfaces"]["#{node[:snmpd][:interface]}"]["addresses"].find {|addr, addr_info| addr_info[:family] == "inet"}.first
  )
end

service "snmpd" do
  supports :status => false, :restart => true, :reload => true
  action [:enable, :start]
  subscribes :restart, resources(:template => "/etc/snmp/snmpd.conf")
  subscribes :restart, resources(:template => "/etc/default/snmpd")
  #subscribes :restart, resources(:package => "snmpd")
end
