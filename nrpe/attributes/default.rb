default[:nrpe][:allowed_hosts] = "127.0.0.1"
default[:nrpe][:interface] = "eth0"
default[:nrpe][:plugin_dir] = "/usr/lib/nagios/plugins"

# load average check: 5, 10 and 15 minute averages
default[:nrpe][:load][:enable] = true
default[:nrpe][:load][:warning] = "3,6,8"
default[:nrpe][:load][:critical] = "6,12,16"

# free memory
default[:nrpe][:free_memory][:enable] = false
default[:nrpe][:free_memory][:warning] = 250
default[:nrpe][:free_memory][:critical] = 150

# free disk space percentage
default[:nrpe][:free_disk][:enable] = true
default[:nrpe][:free_disk][:warning] = "15"
default[:nrpe][:free_disk][:critical] = "10"
