#!/bin/bash
#export DEBIAN_FRONTEND=noninteractive

HOSTNAME=$CONTAINER_NAME
export HADOOP_CONF="/hadoop-3.4.1/etc/hadoop/"

source /etc/profile
#exec /usr/sbin/sshd -D

## core-site.xml
mv $HADOOP_CONF/core-site.xml $HADOOP_CONF/core-site.xml.old
xmlstarlet ed \
  -d "/configuration/property[name='fs.defaultFS']" \
  -s /configuration -t elem -n property -v "" \
  -s /configuration/property[1] -t elem -n name -v "fs.defaultFS" \
  -s /configuration/property[1] -t elem -n value -v "hdfs://$HOSTNAME:9000" \
  -d "/configuration/property[name='dfs.namenode.rpc-bind-host']" \
  -s /configuration -t elem -n property -v "" \
  -s /configuration/property[2] -t elem -n name -v "dfs.namenode.rpc-bind-host" \
  -s /configuration/property[2] -t elem -n value -v "0.0.0.0" \
  $HADOOP_CONF/core-site.xml.old | xmlstarlet fo > $HADOOP_CONF/core-site.xml

service ssh start
su - hadoop -s /bin/bash -c 'echo "This is $HOSTNAME"; echo "source /etc/profile" >> ~/.bashrc; hdfs namenode -format; start-dfs.sh; hdfs dfs -mkdir -p /user/hadoop; hdfs dfs -ls /;'
tail -f /dev/null
