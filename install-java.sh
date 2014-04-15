echo Install java


sudo -E apt-get --yes --force-yes update
sudo -E apt-get install --yes --force-yes python-software-properties

sudo echo oracle-java7-installer shared/accepted-oracle-license-v1-1 select true | sudo /usr/bin/debconf-set-selections
sudo -E add-apt-repository ppa:webupd8team/java
sudo -E apt-get --yes --force-yes update
sudo -E apt-get --yes --force-yes install oracle-java7-installer 
sudo -E apt-get --yes --force-yes install oracle-java7-set-default 
