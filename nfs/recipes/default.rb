package "portmap"

service "portmap" do
    action [ :enable, :start ]
    running true
    supports :status => false, :restart => true
    action :nothing
end

template "/etc/default/portmap" do
  source "portmap.erb"
  owner "root"
  group "root"
  mode "0644"
  notifies :restart, resources(:service => "portmap"), :immediately
end

package "nfs-common"
service "nfs-common" do
    action [ :enable, :start ]
    running true
    supports :status => true, :restart => true
end
