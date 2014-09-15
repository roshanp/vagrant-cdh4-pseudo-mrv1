source /vagrant/centos/provision-hosts.sh
source /vagrant/centos/install-java.sh

echo Install packages

sudo yum install -y curl wget

#Ldap

wget http://dl.fedoraproject.org/pub/epel/6/x86_64/epel-release-6-8.noarch.rpm
wget http://rpms.famillecollet.com/enterprise/remi-release-6.rpm
sudo rpm -Uvh remi-release-6*.rpm epel-release-6*.rpm
sudo yum -y install openldap openldap-clients openldap-servers
sudo mkdir /var/lib/openldap/data
sudo chown -R ldap:ldap /var/lib/openldap

printf "include         /etc/openldap/schema/core.schema\n include         /etc/openldap/schema/cosine.schema \ninclude         /etc/openldap/schema/inetorgperson.schema \ninclude         /etc/openldap/schema/ppolicy.schema \ninclude         /etc/openldap/schema/dyngroup.schema \ninclude         /etc/openldap/schema/java.schema \ninclude         /etc/openldap/schema/misc.schema \ninclude         /etc/openldap/schema/nis.schema \ndatabase bdb \nsuffix \"dc=c3,dc=rdk\" \nrootdn \"cn=Manager,dc=c3,dc=rdk\" \nrootpw password \n \ndirectory /var/lib/openldap/data" | sudo tee /etc/openldap/slapd.conf
sudo slapd

# Load c3.ldiff
cat > c3.ldif <<EOF
# intended for inclusion in ldap tree.
# maintains necessary ldap taxonomy to support C3 user authorization per c3-common-security as of v1.0.0.
# replace all instances of dc=c3,dc=rdk
# assumes ldap root of: dc=c3,dc=rdk
# ldapmodify -a -f $1 -D cn=admin,dc=c3,dc=rdk -W -Z

dn: dc=c3,dc=rdk
objectClass: dcObject
objectClass: organization
o: C3 Top
dc: c3

dn: cn=Manager,dc=c3,dc=rdk
objectClass: organizationalRole
cn: Manager

dn: ou=C3Groups,dc=c3,dc=rdk
objectClass: top
objectClass: organizationalUnit
ou: ou=C3Groups
description: An organizational unit for the definition of C3 application groups

dn: ou=C3Roles,dc=c3,dc=rdk
objectClass: top
objectClass: organizationalUnit
ou: ou=C3Roles
description: An organizational unit for the definition of C3 application roles

dn: ou=Authorizations,dc=c3,dc=rdk
objectClass: top
objectClass: organizationalUnit
ou: ou=Authorizations
description: An organizational unit for the definition of Accumulo Authorizations

dn: ou=C3People,dc=c3,dc=rdk
objectClass: top
objectClass: organizationalUnit
ou: ou=C3People
description: An organizational unit for the definition of C3 application users

dn: cn=c3users,ou=C3Groups,dc=c3,dc=rdk
objectClass: top
objectClass: groupOfNames
cn: cn=c3users,ou=Group
description: A group of names for the containment of C3 application users
member: uid=c3test_noauth,ou=C3People,dc=c3,dc=rdk
member: uid=c3test_u,ou=C3People,dc=c3,dc=rdk
member: uid=c3test_u_fouo,ou=C3People,dc=c3,dc=rdk

dn: cn=u,ou=Authorizations,dc=c3,dc=rdk
objectClass: top
objectClass: groupOfNames
cn: u
description: A group of names for the containment of C3 application users granted u
member: uid=c3test_u,ou=C3People,dc=c3,dc=rdk
member: uid=c3test_u_fouo,ou=C3People,dc=c3,dc=rdk

dn: cn=fouo,ou=Authorizations,dc=c3,dc=rdk
objectClass: top
objectClass: groupOfNames
cn: fouo
description: A group of names for the containment of C3 application users granted fouo
member: uid=c3test_u_fouo,ou=C3People,dc=c3,dc=rdk

dn: o=Ozone,dc=c3,dc=rdk
objectClass: extensibleObject
objectClass: domain
dc: owf-1
o: Ozone

dn: ou=owfRoles,o=Ozone,dc=c3,dc=rdk
objectClass: organizationalUnit
ou: owfRoles

dn: cn=user,ou=owfRoles,o=Ozone,dc=c3,dc=rdk
objectClass: groupOfNames
cn: user
member: uid=c3test_u_fouo,ou=C3People,dc=c3,dc=rdk
member: uid=c3test_u,ou=C3People,dc=c3,dc=rdk

dn: cn=admin,ou=owfRoles,o=Ozone,dc=c3,dc=rdk
objectClass: groupOfNames
cn: admin
member: uid=c3test_u_fouo,ou=C3People,dc=c3,dc=rdk

dn: uid=c3test_noauth,ou=C3People,dc=c3,dc=rdk
objectClass: top
objectClass: inetOrgPerson
objectClass: person
objectClass: organizationalPerson
cn: c3test_noauth
sn: user
uid: c3test_noauth

dn: uid=c3test_u,ou=C3People,dc=c3,dc=rdk
objectClass: top
objectClass: inetOrgPerson
objectClass: person
objectClass: organizationalPerson
cn: c3test_u
sn: user
uid: c3test_u

dn: uid=c3test_u_fouo,ou=C3People,dc=c3,dc=rdk
objectClass: top
objectClass: inetOrgPerson
objectClass: person
objectClass: organizationalPerson
cn: c3test_u_fouo
sn: user
uid: c3test_u_fouo
EOF

sudo ldapmodify -a -f c3.ldif -D cn=Manager,dc=c3,dc=rdk -w password -c

echo Cloudera Hadoop Install
export ACCUMULO_HOME=/opt/accumulo/accumulo-current
export HADOOP_HOME=/usr/lib/hadoop
export JAVA_HOME=/etc/alternatives/java_sdk

#######Repo
cat > /etc/yum.repos.d/cloudera46.repo <<EOF
[cloudera-cdh46]
name=Cloudera's Distribution for Hadoop, Version 4.6
baseurl=http://archive.cloudera.com/cdh4/redhat/6/x86_64/cdh/4.6.0/
gpgkey = http://archive.cloudera.com/cdh4/redhat/6/x86_64/cdh/RPM-GPG-KEY-cloudera
gpgcheck = 1
EOF

sudo yum install -y hadoop-0.20-conf-pseudo
sudo yum install -y zookeeper-server

echo "Installing Accumulo packages"

#Install Accumulo
sudo curl -L -O http://apache.osuosl.org/accumulo/1.5.1/accumulo-1.5.1-bin.tar.gz
sudo mkdir /opt/accumulo
sudo mkdir /etc/accumulo
sudo tar -zxf accumulo-1.5.1-bin.tar.gz -C /opt/accumulo
sudo ln -s /opt/accumulo/accumulo-1.5.1 /opt/accumulo/accumulo-current
sudo ln -s /opt/accumulo/accumulo-current/conf /etc/accumulo/conf
sudo ln -s /opt/accumulo/accumulo-current/bin/accumulo /usr/bin/accumulo

#Stop all
for x in `cd /etc/init.d ; ls hadoop-0.20-mapreduce-*` ; do sudo -E service $x stop ; done
for x in `cd /etc/init.d ; ls hadoop-hdfs-*` ; do sudo -E service $x stop ; done

#Start Hadoop
sudo -E -u hdfs hdfs namenode -format
for x in `cd /etc/init.d ; ls hadoop-hdfs-*` ; do sudo -E service $x start ; done

#Set up HDFS dirs
sudo -E -u hdfs hadoop fs -mkdir /tmp
sudo -E -u hdfs hadoop fs -chmod -R 1777 /tmp

sudo -E -u hdfs hadoop fs -mkdir -p /var/lib/hadoop-hdfs/cache/mapred/mapred/staging
sudo -E -u hdfs hadoop fs -chmod 1777 /var/lib/hadoop-hdfs/cache/mapred/mapred/staging
sudo -E -u hdfs hadoop fs -chown -R mapred /var/lib/hadoop-hdfs/cache/mapred

sudo -E -u hdfs hadoop fs -ls -R /

sudo -E -u hdfs hadoop fs -mkdir /user/hdfs
sudo -E -u hdfs hadoop fs -chown hdfs /user/hdfs

#Start mapred
for x in `cd /etc/init.d ; ls hadoop-0.20-mapreduce-*` ; do sudo -E service $x start ; done

#Configure Accumulo
echo "vm.swappiness = 0" | sudo tee -a /etc/sysctl.conf
echo "# disable ipv6" | sudo tee -a /etc/sysctl.conf
echo "net.ipv6.conf.all.disable_ipv6 = 1" | sudo tee -a /etc/sysctl.conf
echo "net.ipv6.conf.default.disable_ipv6 = 1" | sudo tee -a /etc/sysctl.conf
echo "net.ipv6.conf.lo.disable_ipv6 = 1" | sudo tee -a /etc/sysctl.conf

sudo sysctl -p

sudo cp /etc/accumulo/conf/examples/512MB/standalone/* /etc/accumulo/conf/

sudo -E sed -i 's/<\/configuration>/<property><name>dfs.datanode.synconclose<\/name><value>true<\/value><\/property><\/configuration>/g' /etc/hadoop/conf/core-site.xml
sudo -E sed -i 's/$HADOOP_PREFIX\/conf/$HADOOP_PREFIX\/etc\/hadoop/g' /etc/accumulo/conf/accumulo-env.sh
sudo -E sed -i 's/\/path\/to\/hadoop/\/usr\/lib\/hadoop/g' /etc/accumulo/conf/accumulo-env.sh
sudo -E sed -i 's/\/path\/to\/java/\/etc\/alternatives\/java_sdk/g' /etc/accumulo/conf/accumulo-env.sh
sudo -E sed -i 's/\/path\/to\/zookeeper/\/usr\/lib\/zookeeper/g' /etc/accumulo/conf/accumulo-env.sh

# Monitor needs to bind to right interface
cat > /etc/accumulo/conf/monitor <<EOF
$HOSTNAME
EOF

#Overwrite accumulo site
cat > /etc/accumulo/conf/accumulo-site.xml << EOF
<?xml version="1.0" encoding="UTF-8"?>
<!--
  Licensed to the Apache Software Foundation (ASF) under one or more
  contributor license agreements.  See the NOTICE file distributed with
  this work for additional information regarding copyright ownership.
  The ASF licenses this file to You under the Apache License, Version 2.0
  (the "License"); you may not use this file except in compliance with
  the License.  You may obtain a copy of the License at

      http://www.apache.org/licenses/LICENSE-2.0

  Unless required by applicable law or agreed to in writing, software
  distributed under the License is distributed on an "AS IS" BASIS,
  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
  See the License for the specific language governing permissions and
  limitations under the License.
-->
<?xml-stylesheet type="text/xsl" href="configuration.xsl"?>

<configuration>
  <!-- Put your site-specific accumulo configurations here. The available configuration values along with their defaults are documented in docs/config.html Unless
    you are simply testing at your workstation, you will most definitely need to change the three entries below. -->

  <property>
    <name>instance.zookeeper.host</name>
    <value>localhost:2181</value>
    <description>comma separated list of zookeeper servers</description>
  </property>

  <property>
    <name>logger.dir.walog</name>
    <value>walogs</value>
    <description>The property only needs to be set if upgrading from 1.4 which used to store write-ahead logs on the local
      filesystem. In 1.5 write-ahead logs are stored in DFS.  When 1.5 is started for the first time it will copy any 1.4
      write ahead logs into DFS.  It is possible to specify a comma-separated list of directories.
    </description>
  </property>

  <property>
    <name>instance.secret</name>
    <value>secret</value>
    <description>A secret unique to a given instance that all servers
      must know in order to communicate with one another.
      Change it before initialization. To
      change it later use ./bin/accumulo org.apache.accumulo.server.util.ChangeSecret --old [oldpasswd] --new [newpasswd],
      and then update this file.
    </description>
  </property>

  <property>
    <name>tserver.memory.maps.max</name>
    <value>80M</value>
  </property>

  <property>
    <name>tserver.memory.maps.native.enabled</name>
    <value>false</value>
  </property>

  <property>
    <name>tserver.cache.data.size</name>
    <value>7M</value>
  </property>

  <property>
    <name>tserver.cache.index.size</name>
    <value>20M</value>
  </property>

  <property>
    <name>trace.token.property.password</name>
    <!-- change this to the root users password, and/or change the user below -->
    <value>secret</value>
  </property>

  <property>
    <name>trace.user</name>
    <value>root</value>
  </property>

  <property>
    <name>tserver.sort.buffer.size</name>
    <value>50M</value>
  </property>

  <property>
    <name>tserver.walog.max.size</name>
    <value>100M</value>
  </property>

  <property>
    <name>general.classpaths</name>
    <!--
       Add the following for Hadoop2, actual needs depend on Hadoop installation details.
       This list may be excessive, but this should cause no issues. Append these values
       after the $HADOOP_PREFIX entries

       $HADOOP_PREFIX/share/hadoop/common/.*.jar,
       $HADOOP_PREFIX/share/hadoop/common/lib/.*.jar,
       $HADOOP_PREFIX/share/hadoop/hdfs/.*.jar,
       $HADOOP_PREFIX/share/hadoop/mapreduce/.*.jar,
       $HADOOP_PREFIX/share/hadoop/yarn/.*.jar,
       /usr/lib/hadoop/.*.jar,
       /usr/lib/hadoop/lib/.*.jar,
       /usr/lib/hadoop-hdfs/.*.jar,
       /usr/lib/hadoop-mapreduce/.*.jar,
       /usr/lib/hadoop-yarn/.*.jar,
    -->
    <value>
      \$ACCUMULO_HOME/server/target/classes/,
      \$ACCUMULO_HOME/lib/accumulo-server.jar,
      \$ACCUMULO_HOME/core/target/classes/,
      \$ACCUMULO_HOME/lib/accumulo-core.jar,
      \$ACCUMULO_HOME/start/target/classes/,
      \$ACCUMULO_HOME/lib/accumulo-start.jar,
      \$ACCUMULO_HOME/fate/target/classes/,
      \$ACCUMULO_HOME/lib/accumulo-fate.jar,
      \$ACCUMULO_HOME/proxy/target/classes/,
      \$ACCUMULO_HOME/lib/accumulo-proxy.jar,
      \$ACCUMULO_HOME/lib/[^.].*.jar,
      \$ZOOKEEPER_HOME/zookeeper[^.].*.jar,
      \$HADOOP_CONF_DIR,
      \$HADOOP_PREFIX/[^.].*.jar,
      \$HADOOP_PREFIX/lib/[^.].*.jar,
      \$HADOOP_PREFIX/share/hadoop/common/.*.jar,
       \$HADOOP_PREFIX/share/hadoop/common/lib/.*.jar,
       \$HADOOP_PREFIX/share/hadoop/hdfs/.*.jar,
       \$HADOOP_PREFIX/share/hadoop/mapreduce/.*.jar,
       \$HADOOP_PREFIX/share/hadoop/yarn/.*.jar,
       /usr/lib/hadoop/.*.jar,
       /usr/lib/hadoop/lib/.*.jar,
       /usr/lib/hadoop-hdfs/.*.jar,
       /usr/lib/hadoop-0.20-mapreduce/.*.jar,
       /usr/lib/hadoop-yarn/.*.jar,
    </value>
    <description>Classpaths that accumulo checks for updates and class files.
      When using the Security Manager, please remove the ".../target/classes/" values.
    </description>
  </property>
</configuration>
EOF

#Zookeeper start
sudo -E service zookeeper-server init
sudo -E service zookeeper-server start

#"Initializing Accumulo"

sudo groupadd accumulo
sudo useradd -g accumulo -m accumulo

sudo chown -R accumulo:accumulo /var/log/accumulo
sudo chown -R accumulo:accumulo /opt/accumulo

sudo -E -u hdfs hdfs dfs -rmr /accumulo
sudo -E -u hdfs hdfs dfs -mkdir /accumulo /user/accumulo
sudo -E -u hdfs hdfs dfs -chown -R accumulo:hadoop /accumulo /user/accumulo
sudo -E -u hdfs hdfs dfs -chmod 751 /accumulo
sudo -E -u hdfs hdfs dfs -chmod 750 /user/accumulo

sudo -E -u accumulo accumulo init --instance-name accumulo --password secret

#Starting Accumulo
sudo -E -u accumulo /opt/accumulo/accumulo-current/bin/start-all.sh

#Install Storm
sudo curl -L -O http://www.eng.lsu.edu/mirrors/apache/incubator/storm/apache-storm-0.9.1-incubating/apache-storm-0.9.1-incubating.tar.gz
sudo mkdir /opt/storm
sudo tar -zxf apache-storm-0.9.1-incubating.tar.gz -C /opt/storm
sudo ln -s /opt/storm/apache-storm-0.9.1-incubating /opt/storm/storm-current
sudo ln -s /opt/storm/storm-current/bin/storm /usr/bin/storm

sudo groupadd storm
sudo useradd -g storm -m storm

sudo chown -R storm:storm /opt/storm

sudo cat > /opt/storm/storm-current/conf/storm.yaml << EOF
storm.local.dir: "/tmp/storm-local"
ui.port: 7070
EOF

#Copy new commons-io to storm lib
sudo cp /usr/lib/hadoop-hdfs/lib/commons-io-2.1.jar /opt/storm/storm-current/lib/
sudo rm -rf /opt/storm/storm-current/lib/commons-io-1.4.jar

#Start Storm
sudo -E -u storm nohup storm nimbus &
sudo -E -u storm nohup storm ui &
sudo -E -u storm nohup storm supervisor &

#Install Jetty 9
sudo curl -L -O http://download.eclipse.org/jetty/stable-9/dist/jetty-distribution-9.2.2.v20140723.tar.gz
sudo mkdir /opt/jetty
sudo tar -zxf jetty-distribution-9.2.2.v20140723.tar.gz -C /opt/jetty
sudo ln -s /opt/jetty/jetty-distribution-9.2.2.v20140723 /opt/jetty/jetty-current

#webadmin user
sudo groupadd webadmin
sudo useradd -g webadmin -m webadmin
sudo chown -R webadmin:webadmin /opt/jetty

#install depot
sudo curl -L -O http://enlighten.is-leet.com:8081/nexus/service/local/repositories/releases/content/depot/depot-iterators/1.0.0/depot-iterators-1.0.0-rpm.rpm
sudo rpm -Uvh depot-iterators-1.0.0-rpm.rpm
sudo curl -L -O http://enlighten.is-leet.com:8081/nexus/service/local/repositories/releases/content/depot/depot-admin/1.0.0/depot-admin-1.0.0-rpm.rpm
sudo rpm -Uvh depot-admin-1.0.0-rpm.rpm
sh /opt/depot/bin/create_tables.sh -u root -p secret

#c3 properties
cat > /opt/jetty/jetty-current/resources/c3.properties << EOF
ldap.url=ldap://localhost:389/dc=c3,dc=rdk
ldap.manager.dn=cn=Manager,dc=c3,dc=rdk
ldap.manager.password=password
ldap.user.search.base=ou=C3People
ldap.user.search.filter=(uid={0})
ldap.group.search.base=ou=Authorizations
ldap.group.search.filter=(member={0})
ldap.cache.config.spec=expireAfterWrite=5m
mock.admin.roles=ADMIN,CATALOGADMIN
user.details.service.mode=mock
authorizations.strategy.ref=unclassAuthoriziationsStrategy

accumulo.instance=accumulo
accumulo.zookeepers=localhost:2181
accumulo.username=root
accumulo.password=secret
EOF

# Pull resolver into jetty
curl -L http://enlighten.is-leet.com:8081/nexus/service/local/repositories/snapshots/content/c3/c3-web-resolver/1.0.2-SNAPSHOT/c3-web-resolver-1.0.2-20140906.035944-202.war > /opt/jetty/jetty-current/webapps/resolver.war

# Start jetty
java -jar /opt/jetty/jetty-current/start.jar jetty.port=8081

echo 'Done!'
