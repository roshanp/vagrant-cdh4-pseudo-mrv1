# Cluster architecture

This is a single-node CDH4 cluster with the following services:

* Node `cloudera0`
  * HDFS: 
    * namenode
    * datanode
  * Map/Reduce v1
    * jobtracker
    * tasktracker

# Installation

1. git clone https://github.com/sgomezvillamor/vagrant-cdh4-pseudo-mrv1
2. cd vagrant-cdh4-pseudo-mrv1
3. vagrant up

# Webapps

* HDFS http://192.168.56.20:50070/ 
* Map/Reduce http://192.168.56.20:50030/

