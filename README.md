# Cluster architecture

This is a single-node CDH4 cluster with the following services:

* Node `cloudera0`
  * HDFS: 
    * namenode
    * datanode
  * Map/Reduce v1
    * jobtracker
    * tasktracker

All nodes have a `vagrant` user (password: `vagrant`).

# Installation

```
git clone https://github.com/sgomezvillamor/vagrant-cdh4-pseudo-mrv1
cd vagrant-cdh4-pseudo-mrv1
vagrant up
```

# Webapps

* HDFS http://192.168.56.20:50070/ 
* Map/Reduce http://192.168.56.20:50030/

# Considerations

## HDFS permissions

If you need to disable user permissions in HDFS add the following parameter to `/etc/hadoop/conf/hdfs-site.xml` (restarting services is required):

```
  <property>
    <name>dfs.permissions</name>
    <value>false</value>
  </property>
```
