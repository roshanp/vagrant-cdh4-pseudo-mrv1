source /vagrant/install-java.sh

echo Install packages

sudo -E apt-get --yes --force-yes update
sudo -E apt-get --yes --force-yes install curl wget
sudo -E mkdir -p /etc/apt/sources.list.d
sudo -E touch /etc/apt/sources.list.d/cloudera.list
echo "deb [arch=amd64] http://archive.cloudera.com/cdh4/ubuntu/precise/amd64/cdh precise-cdh4 contrib" > /etc/apt/sources.list.d/cloudera.list
echo "deb-src http://archive.cloudera.com/cdh4/ubuntu/precise/amd64/cdh precise-cdh4 contrib" >> /etc/apt/sources.list.d/cloudera.list
curl -s http://archive.cloudera.com/cdh4/ubuntu/precise/amd64/cdh/archive.key > precise.key
sudo -E apt-key add precise.key
sudo -E apt-get --yes --force-yes update
sudo -E apt-get --yes --force-yes install hadoop-0.20-conf-pseudo
dpkg -L hadoop-0.20-conf-pseudo
ls /etc/hadoop/conf.pseudo.mr1

echo Stop all

for x in `cd /etc/init.d ; ls hadoop-0.20-mapreduce-*` ; do sudo -E service $x stop ; done
for x in `cd /etc/init.d ; ls hadoop-hdfs-*` ; do sudo -E service $x stop ; done

echo Edit config files

sudo -E sed -i 's/localhost:8020/192.168.56.20:8020/g' /etc/hadoop/conf/core-site.xml
sudo -E sed -i 's/localhost:8020/192.168.56.20:8020/g' /etc/hadoop/conf.pseudo.mr1/core-site.xml

sudo -E sed -i 's/localhost:8021/192.168.56.20:8021/g' /etc/hadoop/conf/mapred-site.xml
sudo -E sed -i 's/localhost:8021/192.168.56.20:8021/g' /etc/hadoop/conf.pseudo.mr1/mapred-site.xml

echo disable dfs permission
sudo -E python /vagrant/disable-dfs-permission.py

echo add hostname on 192.168.56.20
echo '192.168.56.20   localHdfsCluster' | sudo tee -a /etc/hosts > /dev/null 

echo Format namenode

sudo -E -u hdfs hdfs namenode -format

echo Start HDFS

for x in `cd /etc/init.d ; ls hadoop-hdfs-*` ; do sudo -E service $x start ; done

sudo -E -u hdfs hadoop fs -mkdir /tmp
sudo -E -u hdfs hadoop fs -chmod -R 1777 /tmp

sudo -E -u hdfs hadoop fs -mkdir -p /var/lib/hadoop-hdfs/cache/mapred/mapred/staging
sudo -E -u hdfs hadoop fs -chmod 1777 /var/lib/hadoop-hdfs/cache/mapred/mapred/staging
sudo -E -u hdfs hadoop fs -chown -R mapred /var/lib/hadoop-hdfs/cache/mapred

sudo -E -u hdfs hadoop fs -ls -R /

sudo -E -u hdfs hadoop fs -mkdir /user/hdfs 
sudo -E -u hdfs hadoop fs -chown hdfs /user/hdfs

echo Start MapReduce

for x in `cd /etc/init.d ; ls hadoop-0.20-mapreduce-*` ; do sudo -E service $x start ; done

