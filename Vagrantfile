# -*- mode: ruby -*-
# vi: set ft=ruby :


Vagrant::Config.run do |config|
  config.vm.box = "UbuntuPrecise64"
  config.vm.box_url = "http://files.vagrantup.com/precise64.box"

  config.vm.provision :shell, :inline => "source /vagrant/install-cdh4.sh"

  config.vm.define :cloudera0 do |cloudera0_config|
    cloudera0_config.vm.host_name = "cloudera0"
    cloudera0_config.vm.network :hostonly, "192.168.56.20"
    cloudera0_config.vm.customize ["modifyvm", :id, "--memory", 2048]
  end

end
