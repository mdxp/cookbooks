include_recipe "nfs::default"

if node[:nfs] && node[:nfs][:mounts]
  node[:nfs][:mounts].each do |target, config|
    directory target do
      recursive true
      owner (config[:owner]||'root')
      group (config[:owner]||'root')
    end

    mount target do
      fstype "nfs"
      options config[:options] || %w(rsize=32768,wsize=32768,bg,hard,nfsvers=3,intr,tcp,noatime,timeo=14)
      device config[:device]
      dump 0
      pass 0
      # mount and add to fstab. set to 'disable' to remove it
      action [:enable, :mount]
    end
  end
else
  Chef::Log.warn "You included the NFS client recipe without defining nfs mounts."
end
