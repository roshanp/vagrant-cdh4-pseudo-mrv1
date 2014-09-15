# -*- mode: ruby -*-
# vi: set ft=ruby :


Vagrant.configure("2") do |config|
  config.vm.box = "Centos65"
  config.vm.box_url = "https://github.com/2creatives/vagrant-centos/releases/download/v6.5.3/centos65-x86_64-20140116.box"
  # config.vm.network "public_network"
  config.vm.network "private_network", ip: "192.168.50.4"
  config.vm.hostname = "localdev"

  config.vm.provision :shell, :inline => "source /vagrant/centos/install-cdh4.sh"

  config.vm.provider "virtualbox" do |v|
    v.memory = 2048
    v.cpus = 2
    v.customize ["modifyvm", :id, "--cpuexecutioncap", "50"]
  end

end
