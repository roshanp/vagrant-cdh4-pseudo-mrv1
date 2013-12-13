# -*- mode: ruby -*-
# vi: set ft=ruby :


Vagrant::Config.run do |config|
  config.vm.box = "UbuntuPrecise64"
  config.vm.box_url = "http://files.vagrantup.com/precise64.box"

  config.vm.provision :shell, :inline => "source /vagrant/files/install-cdh4.sh"

  config.vm.define :cdh4 do |cdh4_config|
    cdh4_config.vm.host_name = "cdh4"
    cdh4_config.vm.network :hostonly, "192.168.56.20"
    cdh4_config.vm.customize ["modifyvm", :id, "--memory", 2048]
  end

end
