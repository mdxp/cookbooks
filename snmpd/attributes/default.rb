default[:snmpd][:monitoring_ips] = ["127.0.0.1"]
default[:snmpd][:interface] = "eth0"
default[:snmpd][:community] = "public"
default[:snmpd][:syslocation] = "here"
default[:snmpd][:syscontact] = "root <root@#{node[:domain]}>"
default[:snmpd][:disks] = node[:filesystem].keys.select { |k| k =~ /\A\/dev\// }.map { |d| node[:filesystem][d][:mount] }
default[:snmpd][:execs] = []
# default[:snmpd][:execs] = [
#   {
#     :name => "postfix_queue_size",
#     :command => "/usr/local/bin/postfix_queue_size"
#   },
#   {
#     :name => "sda_smart_errors",
#     :command => "/usr/local/bin/smart_errors /dev/sda"
#   }
# ]
