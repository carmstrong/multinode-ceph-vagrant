# -*- mode: ruby -*-
# vi: set ft=ruby :

Vagrant.configure("2") do |config|
  config.vm.box = "ubuntu/bionic64"
  config.ssh.forward_agent = true
  config.ssh.insert_key = true
  config.hostmanager.enabled = true
  config.cache.scope = :box

  config.trigger.before :up do |t|
    t.info = "Ensure ssh key for distribution to machines exists.."
    t.run = {path: "init_host.sh"}
  end

  # The Ceph client will be our client machine to mount volumes and interact with the cluster
  config.vm.define "ceph-client" do |client|
    client.vm.hostname = "ceph-client"
    client.vm.network :private_network, ip: "172.21.12.11"
    # ceph-deploy will assume remote machines have python2 installed
    config.vm.provision :shell, :inline => "DEBIAN_FRONTEND=noninteractive apt-get update && apt-get install -yq python", :privileged => true
    config.vm.provision "file", source: "key_rsa.pub", destination: "authorized_keys"
    config.vm.provision :shell, :inline => "mkdir -p /root/.ssh && cp authorized_keys /root/.ssh/", :privileged => true
  end

  # We provision three nodes to be Ceph servers
  (1..3).each do |i|
    config.vm.define "ceph-server-#{i}" do |config|
      config.vm.hostname = "ceph-server-#{i}"
      config.vm.network :private_network, ip: "172.21.12.#{i+11}"
      # ceph-deploy will assume remote machines have python2 installed
      config.vm.provision :shell, :inline => "DEBIAN_FRONTEND=noninteractive apt-get update && apt-get install -yq ntp python", :privileged => true
      config.vm.provision "file", source: "key_rsa.pub", destination: "authorized_keys"
      config.vm.provision :shell, :inline => "mkdir -p /root/.ssh && cp authorized_keys /root/.ssh/", :privileged => true
    end
  end

  # We need one Ceph admin machine to manage the cluster
  config.vm.define "ceph-admin", primary: true do |admin|
    admin.vm.hostname = "ceph-admin"
    admin.vm.network :private_network, ip: "172.21.12.10"
    admin.vm.provision "file", source: "key_rsa", destination: ".ssh/id_rsa"
    admin.vm.provision "file", source: "key_rsa.pub", destination: ".ssh/id_rsa.pub"
    admin.vm.provision "file", source: "init.sh", destination: "init.sh"
    admin.vm.provision :shell, :inline => "./init.sh", :privileged => true
  end
end
