source /vagrant/files/install-java.sh

echo Install packages

sudo apt-get --yes --force-yes update
sudo apt-get --yes --force-yes install curl wget
sudo mkdir -p /etc/apt/sources.list.d
sudo touch /etc/apt/sources.list.d/cloudera.list
echo "deb [arch=amd64] http://archive.cloudera.com/cdh4/ubuntu/precise/amd64/cdh precise-cdh4 contrib" > /etc/apt/sources.list.d/cloudera.list
echo "deb-src http://archive.cloudera.com/cdh4/ubuntu/precise/amd64/cdh precise-cdh4 contrib" >> /etc/apt/sources.list.d/cloudera.list
curl -s http://archive.cloudera.com/cdh4/ubuntu/precise/amd64/cdh/archive.key > precise.key
sudo apt-key add precise.key
sudo apt-get --yes --force-yes update
sudo apt-get --yes --force-yes install hadoop-0.20-conf-pseudo
dpkg -L hadoop-0.20-conf-pseudo
ls /etc/hadoop/conf.pseudo.mr1

echo Format namenode

sudo -E -u hdfs hdfs namenode -format

echo Start HDFS

for x in `cd /etc/init.d ; ls hadoop-hdfs-*` ; do sudo service $x start ; done

sudo -E -u hdfs hadoop fs -mkdir /tmp
sudo -E -u hdfs hadoop fs -chmod -R 1777 /tmp

sudo -E -u hdfs hadoop fs -mkdir -p /var/lib/hadoop-hdfs/cache/mapred/mapred/staging
sudo -E -u hdfs hadoop fs -chmod 1777 /var/lib/hadoop-hdfs/cache/mapred/mapred/staging
sudo -E -u hdfs hadoop fs -chown -R mapred /var/lib/hadoop-hdfs/cache/mapred

sudo -E -u hdfs hadoop fs -ls -R /

sudo -E -u hdfs hadoop fs -mkdir /user/hdfs 
sudo -E -u hdfs hadoop fs -chown hdfs /user/hdfs

echo Start MapReduce

for x in `cd /etc/init.d ; ls hadoop-0.20-mapreduce-*` ; do sudo service $x start ; done

