# hdfs-local-container
[![Docker Image](https://github.com/sukumaar/hdfs-local-container/actions/workflows/docker-image.yml/badge.svg)](https://github.com/sukumaar/hdfs-local-container/actions/workflows/docker-image.yml)
![GitHub License](https://img.shields.io/github/license/sukumaar/hdfs-local-container?style=plastic)
![Docker Pulls](https://img.shields.io/docker/pulls/sukumaar/hdfs-local?style=plastic&logo=docker&cacheSeconds=60)
![Docker Image Size](https://img.shields.io/docker/image-size/sukumaar/hdfs-local?style=plastic&logo=docker)

## What it is?
HDFS local single node container for testing
## Building and deployment
### Building image locally
```bash
$ git clone git@github.com:sukumaar/hdfs-local-container.git
$ cd hdfs-local-container
# using hdfs-local as image name you can choose your own
$ docker build -t hdfs-local .
```
### or
## Docker pull
```bash
docker pull sukumaar/hdfs-local:latest
```

### Starting container
- CONTAINER_NAME environment variable is required, it's value should be name of your container from your `docker run` command
```bash
$ docker run -e CONTAINER_NAME=namenode \
-d --name namenode \ 
-p 9000:9000 -p 9870:9870  -p 9866:9866 -p 9864:9864 -p 9867:9867 \ 
--replace hdfs-local
```


### CLI Usage
```bash
$ docker exec -it namenode /bin/bash -c "su hadoop"
hadoop@946b4517b87c:/$ 
hadoop@946b4517b87c:/$ cd ~
hadoop@946b4517b87c:~$ hadoop fs -ls
# create/upload some sample file on local filesystem of container, example: data.csv
hadoop@946b4517b87c:~$ hadoop fs -put data.csv
```

### Spark usage
- Do these steps if spark is not on the same machine where container is hosted
    - You need to have ssh access to machine where conatainer is hosted/running
    - Ssh port forwarding of these ports 9000, 9870, 9866, 9864, 9867
- If spark shell is running on the same machine skip previous step
- Spark sample code 
``` bash
scala>  val df = spark.read.text("hdfs://localhost:9000/user/hadoop/data.csv")
df: org.apache.spark.sql.DataFrame = [value: string]

scala> df.show
+--------------------+
|               value|
+--------------------+
|id,name,departmen...|
|1,John Doe,Engine...|
|2,Jane Smith,Mark...|
|3,Robert Brown,Sa...|
|4,Emily Davis,Eng...|
|5,Michael Wilson,...|
|6,Sophia Taylor,F...|
|7,David Miller,Ma...|
|8,Olivia Anderson...|
|9,Daniel Thomas,S...|
|10,Ava Martin,HR,...|
+--------------------+
```
