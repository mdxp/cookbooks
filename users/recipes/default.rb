package "ruby-shadow" do
  package_name value_for_platform(
    [ "centos", "redhat", "fedora"] => { "default" => "ruby-shadow" },
    ["debian", "ubuntu"] => { "default" => "libshadow-ruby1.8" },
    "default" => "ruby-shadow"
  )
  action :install
end

# ensure active groups exist and can be used for new users
node[:active_groups].each do |agroup|
    group = data_bag_item("groups",agroup)
    
    group group['id'] do
     gid group['gid']
    end
end

# create/manage users
search(:users, node[:active_groups].collect {|gr| "groups:#{gr.to_s}" }.join(" OR ") ).each do |user|
  home_dir = user['home'] || "/home/#{user['id']}"
  active_grp = user['groups'] & node[:active_groups]

  user user['id'] do
     comment user['comment'] if user['comment']
     uid user['uid'] if user['uid']
     gid active_grp.first
     home home_dir
     shell user['shell'] || "/bin/bash"
     password user['password'] if user['password']
     supports :manage_home => true
     action [:create, :manage]
  end
  
  # ssh keys
  if user['ssh_key']
     directory "#{home_dir}/.ssh" do
       action :create
       owner user['id']
       group active_grp.first.to_s
       mode 0700
    end

    template "#{home_dir}/.ssh/authorized_keys" do
       source "authorized_keys.erb"
      action :create
      owner user['id']
       group active_grp.first.to_s
       variables(:keys => user['ssh_key'])
       mode 0600
    end
  end
  
  if (user['local_files'] == true )
    remote_directory home_dir do
      source "users/#{user['id']}"
      owner user['id']
      group active_grp.first.to_s
      files_owner user['id']
      files_group active_grp.first.to_s
      ignore_failure true
    end
  end
 
end

# add users to their other groups
node[:active_groups].each do |agroup|
  group = data_bag_item("groups",agroup)
  user_group = Array.new
  search(:users, "groups:#{group['id']}").each do |user|
     user_group << user['id']
  end

  group group['id'] do
     gid group['gid']
     members user_group
     append true
  end
 
end
