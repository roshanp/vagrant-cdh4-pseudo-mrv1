# -*- mode: ruby -*-
# vi: set ft=ruby :


Vagrant.configure("2") do |config|
  config.vm.box = "UbuntuPrecise64"
  config.vm.box_url = "http://files.vagrantup.com/precise64.box"
  # config.vm.network "public_network"
  config.vm.network "private_network", ip: "192.168.50.4"
  config.vm.hostname = "localdev"

  config.vm.provision :shell, :inline => "source /vagrant/install-cdh4.sh"

  config.vm.provider "virtualbox" do |v|
    v.memory = 2048
    v.cpus = 2
    v.customize ["modifyvm", :id, "--cpuexecutioncap", "50"]
  end

end
