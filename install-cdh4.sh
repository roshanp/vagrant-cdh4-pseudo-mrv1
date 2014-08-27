source /vagrant/provision-hosts.sh
source /vagrant/install-java.sh

echo Install packages

sudo -E apt-get --yes --force-yes update
sudo -E apt-get --yes --force-yes install curl wget
sudo -E mkdir -p /etc/apt/sources.list.d
sudo -E touch /etc/apt/sources.list.d/cloudera.list

echo "deb [arch=amd64] http://archive.cloudera.com/cdh4/ubuntu/precise/amd64/cdh precise-cdh4 contrib" > /etc/apt/sources.list.d/cloudera.list
echo "deb-src http://archive.cloudera.com/cdh4/ubuntu/precise/amd64/cdh precise-cdh4 contrib" >> /etc/apt/sources.list.d/cloudera.list

sudo -E touch /etc/apt/sources.list.d/cloudera-accumulo.list

echo "deb [arch=amd64] http://archive.cloudera.com/accumulo/ubuntu/precise/amd64/cdh precise-cdh4 contrib" > /etc/apt/sources.list.d/cloudera-accumulo.list
echo "deb-src http://archive.cloudera.com/accumulo/ubuntu/precise/amd64/cdh precise-cdh4 contrib" >> /etc/apt/sources.list.d/cloudera-accumulo.list

curl -s http://archive.cloudera.com/cdh4/ubuntu/precise/amd64/cdh/archive.key > precise.key
sudo -E apt-key add precise.key
sudo -E apt-get --yes --force-yes update
sudo -E apt-get --yes --force-yes install hadoop-0.20-conf-pseudo
dpkg -L hadoop-0.20-conf-pseudo
ls /etc/hadoop/conf.pseudo.mr1

echo "Installing Zookeeper Server"

sudo apt-get install zookeeper-server

echo "Installing Accumulo packages"

curl -L http://apache.tradebit.com/pub/accumulo/1.5.1/accumulo-1.5.1-bin.deb > /tmp/accumulo-1.5.1-bin.deb
sudo dpkg -i /tmp/accumulo-1.5.1-bin.deb

echo Stop all

for x in `cd /etc/init.d ; ls hadoop-0.20-mapreduce-*` ; do sudo -E service $x stop ; done
for x in `cd /etc/init.d ; ls hadoop-hdfs-*` ; do sudo -E service $x stop ; done

echo Edit config files

sudo -E sed -i 's/localhost:8020/'$HOSTNAME':8020/g' /etc/hadoop/conf/core-site.xml
sudo -E sed -i 's/localhost:8020/'$HOSTNAME':8020/g' /etc/hadoop/conf.pseudo.mr1/core-site.xml

sudo -E sed -i 's/localhost:8021/'$HOSTNAME':8021/g' /etc/hadoop/conf/mapred-site.xml
sudo -E sed -i 's/localhost:8021/'$HOSTNAME':8021/g' /etc/hadoop/conf.pseudo.mr1/mapred-site.xml

echo disable dfs permission
sudo -E python /vagrant/disable-dfs-permission.py

IP=`/sbin/ifconfig eth1 | grep 'inet addr:' | cut -d: -f2 | awk '{ print $1}'`
echo add hostname on $IP
echo $IP'   '$HOSTNAME | sudo tee -a /etc/hosts > /dev/null

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

echo "Configuring Accumulo"

echo "vm.swappiness = 0" | sudo tee -a /etc/sysctl.conf
echo "# disable ipv6" | sudo tee -a /etc/sysctl.conf
echo "net.ipv6.conf.all.disable_ipv6 = 1" | sudo tee -a /etc/sysctl.conf
echo "net.ipv6.conf.default.disable_ipv6 = 1" | sudo tee -a /etc/sysctl.conf
echo "net.ipv6.conf.lo.disable_ipv6 = 1" | sudo tee -a /etc/sysctl.conf

sudo sysctl -p

sudo cp /etc/accumulo/conf/examples/512MB/standalone/* /etc/accumulo/conf/

sudo -E sed -i 's/<\/configuration>/<property><name>dfs.datanode.synconclose<\/name><value>true<\/value><\/property><\/configuration>/g' /etc/hadoop/conf/core-site.xml
sudo -E sed -i 's/$HADOOP_PREFIX\/conf/$HADOOP_PREFIX\/etc\/hadoop/g' /etc/accumulo/conf/accumulo-env.sh
sudo cp /vagrant/accumulo-site.xml /etc/accumulo/conf/

cat > /etc/accumulo/conf/masters <<EOF
localdev
EOF

cat > /etc/accumulo/conf/slaves <<EOF
localdev
EOF

cat > /etc/accumulo/conf/monitor <<EOF
localdev
EOF

cat > /etc/accumulo/conf/gc <<EOF
localdev
EOF

echo "ACCUMULO_TSERVER_OPTS=\"-Xmx128m -Xms128m\"
ACCUMULO_MASTER_OPTS=\"-Xmx128m -Xms128m\"
ACCUMULO_MONITOR_OPTS=\"-Xmx64m -Xms64m\"
ACCUMULO_GC_OPTS=\"-Xmx64m -Xms64m\"
ACCUMULO_GENERAL_OPTS=\"-XX:+UseConcMarkSweepGC -XX:CMSInitiatingOccupancyFraction=75 -Djava.net.preferIPv4Stack=true\"
ACCUMULO_OTHER_OPTS=\"-Xmx64g -Xms64m\"
ACCUMULO_KILL_CMD='kill -9 %p'" | sudo -E tee /etc/default/accumulo

echo "Starting Zookeeper"

sudo -E service zookeeper-server init
sudo -E service zookeeper-server start

echo "Initializing Accumulo"

sudo groupadd accumulo
sudo useradd -g accumulo -m accumulo

#TODO: logs
sudo chown -R accumulo:accumulo /var/log/accumulo
sudo chown -R accumulo:accumulo /usr/lib/accumulo

sudo -E -u hdfs hadoop fs -mkdir /accumulo /user/accumulo
sudo -E -u hdfs hadoop fs -chown accumulo:supergroup /accumulo /user/accumulo
sudo -E -u hdfs hadoop fs -chmod 751 /accumulo
sudo -E -u hdfs hadoop fs -chmod 750 /user/accumulo

sudo -E -u accumulo accumulo init --instance-name accumulo --password secret

echo "Starting Accumulo"

sudo -E -u accumulo /usr/lib/accumulo/bin/start-all.sh

echo 'Done!'
