default['icinga']['version'] = "1.4.2"
default['icinga']['checksum'] = "506022493295bda95aa2514bfdc3196063ed936655bc60068f61543504b42aa6"
default['icinga']['prefix'] = "/usr/local/icinga"

default['icinga']['sysadmin_email'] = "root@localhost"
default['icinga']['sysadmin_sms_email'] = "root@localhost"

default['icinga']['user'] = "nagios"
default['icinga']['group'] = "nagios"

default['icinga']['server_role'] = "monitoring"
default['icinga']['notifications_enabled']   = 0
default['icinga']['check_external_commands'] = true
default['icinga']['default_contact_groups']  = %w(admins)
default['icinga']['sysadmin'] = "sysadmin"

set['icinga']['conf_dir'] = node['icinga']['prefix'] + "/etc"
set['icinga']['config_dir'] = node['icinga']['conf_dir'] + "/conf.d"
set['icinga']['log_dir'] = node['icinga']['prefix'] + "/var"
set['icinga']['cache_dir'] = node['icinga']['log_dir']
set['icinga']['state_dir'] = node['icinga']['log_dir']
set['icinga']['run_dir'] = node['icinga']['log_dir']
set['icinga']['docroot'] = node['icinga']['prefix'] + "/share/"

# This setting is effectively sets the minimum interval (in seconds) icinga can handle.
# Other interval settings provided in seconds will calculate their actual from this value, since icinga works in 'time units' rather than allowing definitions everywhere in seconds

default['icinga']['templates'] = Mash.new
default['icinga']['interval_length'] = 1

# Provide all interval values in seconds
default['icinga']['default_host']['check_interval']     = 15
default['icinga']['default_host']['retry_interval']     = 15
default['icinga']['default_host']['max_check_attempts'] = 1
default['icinga']['default_host']['notification_interval'] = 300

default['icinga']['default_service']['check_interval']     = 60
default['icinga']['default_service']['retry_interval']     = 15
default['icinga']['default_service']['max_check_attempts'] = 3
default['icinga']['default_service']['notification_interval'] = 1200
