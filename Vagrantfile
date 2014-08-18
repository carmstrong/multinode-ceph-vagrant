# -*- mode: ruby -*-
# vi: set ft=ruby :

Vagrant.configure("2") do |config|
  # some shared setup
  config.vm.box = "ubuntu/trusty64"
  config.ssh.forward_agent = true
  config.hostmanager.enabled = true
  config.cache.scope = :box

  # We need one Ceph admin machine to manage the cluster
  config.vm.define vm_name = "ceph-admin" do |config|
    config.vm.hostname = vm_name
    ip = "172.21.12.1"
    config.vm.network :private_network, ip: ip
    config.vm.provision :shell, :inline => "wget -q -O- 'https://ceph.com/git/?p=ceph.git;a=blob_plain;f=keys/release.asc' | apt-key add -", :privileged => true
    config.vm.provision :shell, :inline => "echo deb http://ceph.com/debian-firefly/ $(lsb_release -sc) main | tee /etc/apt/sources.list.d/ceph.list", :privileged => true
    config.vm.provision :shell, :inline => "DEBIAN_FRONTEND=noninteractive apt-get update && apt-get install -yq ceph-deploy", :privileged => true
  end

  # The Ceph client will be our client machine to mount volumes and interact with the cluster
  config.vm.define vm_name = "ceph-client" do |config|
    config.vm.hostname = vm_name
    ip = "172.21.12.2"
    config.vm.network :private_network, ip: ip
  end

  # We provision three nodes to be Ceph servers
  (1..3).each do |i|
    config.vm.define vm_name = "ceph-server-#{i}" do |config|
      config.vm.hostname = vm_name
      ip = "172.21.12.#{i+2}"
      config.vm.network :private_network, ip: ip
    end
  end
end
