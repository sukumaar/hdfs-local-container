FROM ubuntu:24.10

ARG DEBIAN_FRONTEND=noninteractive
ARG HADOOP_CONF="/hadoop-3.4.1/etc/hadoop/"

ENV CONTAINER_NAME="localhost"

RUN apt update
RUN apt upgrade -y
RUN apt install ssh pdsh wget build-essential curl git curl apt-transport-https xmlstarlet nano openssh-server openssh-client -y
RUN wget -qO - https://packages.adoptium.net/artifactory/api/gpg/key/public | gpg --dearmor | tee /etc/apt/trusted.gpg.d/adoptium.gpg > /dev/null
RUN echo "deb https://packages.adoptium.net/artifactory/deb $(awk -F= '/^VERSION_CODENAME/{print$2}' /etc/os-release) main" | tee /etc/apt/sources.list.d/adoptium.list
RUN apt update 
RUN apt install temurin-8-jdk -y
RUN rm -rf /var/lib/apt/lists/*

RUN wget https://dlcdn.apache.org/hadoop/common/hadoop-3.4.1/hadoop-3.4.1-lean.tar.gz -O /hadoop-3.4.1-lean.tar.gz
RUN tar -xvf /hadoop-3.4.1-lean.tar.gz
RUN chmod 755 -R /hadoop-3.4.1
RUN mkdir /hadoop-3.4.1/logs
RUN chmod 777 -R /hadoop-3.4.1/logs
RUN mkdir -p /var/run/sshd

RUN cat <<EOF >> /etc/profile

HADOOP_HOME="/hadoop-3.4.1"
PATH="\$PATH:\$HADOOP_HOME/bin"
PATH="\$PATH:\$HADOOP_HOME/sbin"

HDFS_NAMENODE_USER=hadoop
HDFS_DATANODE_USER=hadoop
HDFS_SECONDARYNAMENODE_USER=hadoop

JAVA_HOME=/usr/lib/jvm/temurin-8-jdk-amd64/
PATH="\$PATH:\$JAVA_HOME/bin"

EOF

RUN echo "export JAVA_HOME=/usr/lib/jvm/temurin-8-jdk-amd64" > /hadoop-3.4.1/etc/hadoop/hadoop-env.sh

## core-site.xml
## done inside script

## hdfs-site.xml
RUN mv $HADOOP_CONF/hdfs-site.xml $HADOOP_CONF/hdfs-site.xml.old
RUN xmlstarlet ed \
  -d "/configuration/property[name='dfs.replication']" \
  -s /configuration -t elem -n property -v "" \
  -s /configuration/property -t elem -n name -v "dfs.replication" \
  -s /configuration/property -t elem -n value -v "1" \
  $HADOOP_CONF/hdfs-site.xml.old | xmlstarlet fo > $HADOOP_CONF/hdfs-site.xml

## mapred-site.xml
RUN mv $HADOOP_CONF/mapred-site.xml $HADOOP_CONF/mapred-site.xml.default
RUN cat $HADOOP_CONF/mapred-site.xml.default | \
xmlstarlet ed \
  -d "/configuration/property[name='mapreduce.framework.name']" \
  -s /configuration -t elem -n property -v "" \
  -s /configuration/property[1] -t elem -n name -v "mapreduce.framework.name" \
  -s /configuration/property[1] -t elem -n value -v "yarn" \
  -d "/configuration/property[name='mapreduce.application.classpath']" \
  -s /configuration -t elem -n property -v "" \
  -s /configuration/property[2] -t elem -n name -v "mapreduce.application.classpath" \
  -s /configuration/property[2] -t elem -n value -v "$HADOOP_HOME/share/hadoop/mapreduce/*:$HADOOP_HOME/share/hadoop/mapreduce/lib/*" \
  | xmlstarlet fo > $HADOOP_CONF/mapred-site.xml

## yarn-site.xml
RUN mv $HADOOP_CONF/yarn-site.xml $HADOOP_CONF/yarn-site.xml.default
RUN cat $HADOOP_CONF/yarn-site.xml.default | \
xmlstarlet ed \
  -d "/configuration/property[name='yarn.nodemanager.aux-services']" \
  -s /configuration -t elem -n property -v "" \
  -s /configuration/property[1] -t elem -n name -v "yarn.nodemanager.aux-services" \
  -s /configuration/property[1] -t elem -n value -v "mapreduce_shuffle" \
  -d "/configuration/property[name='yarn.nodemanager.env-whitelist']" \
  -s /configuration -t elem -n property -v "" \
  -s /configuration/property[2] -t elem -n name -v "yarn.nodemanager.aux-services" \
  -s /configuration/property[2] -t elem -n value -v "JAVA_HOME,HADOOP_COMMON_HOME,HADOOP_HDFS_HOME,HADOOP_CONF_DIR,CLASSPATH_PREPEND_DISTCACHE,HADOOP_YARN_HOME,HADOOP_HOME,PATH,LANG,TZ,HADOOP_MAPRED_HOME" \
  | xmlstarlet fo > $HADOOP_CONF/yarn-site.xml


# Create a new user (e.g., hadoop) with a home directory
RUN useradd -m -s /bin/bash hadoop

# Set up SSH directory and generate SSH key pair for hadoop
RUN mkdir -p /home/hadoop/.ssh
RUN chown hadoop:hadoop /home/hadoop/.ssh
RUN chmod 700 /home/hadoop/.ssh
RUN su - hadoop -c "ssh-keygen -t rsa -b 4096 -f /home/hadoop/.ssh/id_rsa -N ''"
RUN cp /home/hadoop/.ssh/id_rsa.pub /home/hadoop/.ssh/authorized_keys
RUN chown hadoop:hadoop /home/hadoop/.ssh/authorized_keys
RUN chmod 600 /home/hadoop/.ssh/authorized_keys

# Configure SSH to disable password authentication
RUN sed -i 's/#PermitRootLogin prohibit-password/PermitRootLogin no/' /etc/ssh/sshd_config
RUN sed -i 's/#PasswordAuthentication yes/PasswordAuthentication no/' /etc/ssh/sshd_config
RUN sed -i 's/#PubkeyAuthentication yes/PubkeyAuthentication yes/' /etc/ssh/sshd_config

EXPOSE 22

COPY script.sh /script.sh
RUN chmod +x /script.sh

ENTRYPOINT ["/bin/bash", "-x", "/script.sh"]
