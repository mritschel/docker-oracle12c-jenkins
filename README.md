# Oracle Jenkins Demo Using An Oracle Database 12c Standard Edition 2

## Content

This Dockerfile is based on Maksym Bilenko's work for [sath89/oracle-12c](https://hub.docker.com/r/sath89/oracle-12c/). The resulting image contains the following:

* Ubuntu 14.04.3 LTS
* Oracle Database 12.1.0.2 Standard Edition 2
	* Apex
	* Jenkins
	
Pull the latest trusted build from [here](https://hub.docker.com/r/mritschel/oracle12c-jenkins/).


## Installation

### Using Default Settings (recommended)

Complete the following steps to create a new container:

1. Pull the image

		docker pull mritschel/oracle12c-jenkins

2. Create the container

		docker run -d -p 8080:8080 -p 1521:1521 -p 9090:9090 -h xe --name oracle-jenkins mritschel/oracle12c-jenkins
		
3. wait around **15 minutes** until the Oracle Database and APEX is created. Check logs with ```docker logs oracle-jenkins```. The container is ready to use when the last line in the log is ```Oracle started Successfully ! ;)```. The container stops if an error occurs. Check the logs to determine how to proceed.


### Options

#### Environment Variables

You may set the environment variables in the docker run statement to configure the container setup process. The following table lists all environment variables with its default values:

Environment variable | Default value | Comments
-------------------- | ------------- | --------
DBCA_TOTAL_MEMORY | ```1024``` | Keep in mind that DBCA fails if you set this value too low
ORACLE_BASE | ```/u01/app/oracle``` | Oracle Base directory
ORACLE_HOME | ```$ORACLE_BASE/product/12.1.0/xe``` | Oracle Home directory
ORACLE_DATA | ```/u00/app/oracle/oradata``` | Oracle Data directory
ORACLE_HOME_LISTNER | ```$ORACLE_HOME``` | Oracle Home directory
SERVICE_NAME | ```xe.local.com``` | Oracle service name
PATH | ```$ORACLE_HOME/bin:$PATH``` | Path
NLS_DATE_FORMAT | ```DD.MM.YYYY\ HH24:MI:SS``` | Oracle NLS date format
ORACLE_SID | ```xe``` | The Oracle SID
APEX_PASS | ```0Racle$``` | Set a different initial APEX ADMIN password (the one which must be changed on first login)
PASS | ```oracle``` | Password for SYS and SYSTEM
INSTALL_HOME | ```/tmp/software``` | Install directory

Here's an example run call amending the SYS/SYSTEM password and DBCA memory settings:

```
docker run -e PASS=manager -e DBCA_TOTAL_MEMORY=1536 -d -p 8080:8080 -p 1521:1521 -p 9090:9090 -h xe --name oracle-jenkins mritschel/oracle12c-jenkins
```

#### Volumes

The image defines a volume for ```/jenkins```. You may map this volume for the JENKINS_HOME. Here's an example using a named volume ```/jenkins```:

```
docker run -v /jenkins:/jenkins -d -p 8080:8080 -p 1521:1521 -p 9090:9090 -h xe --name oracle-jenkins mritschel/oracle12c-jenkins
```

## Access

### Access Jenkins

[http://localhost:8080/](http://localhost:8080/)

The initial password for jekins is stared in /jenkins/secrets/initialAdminPassword

### Access APEX

[http://localhost:9090/apex/](http://localhost:9090/apex/)

Property | Value 
-------- | -----
Workspace | INTERNAL
User | ADMIN
Password | Oracle12c!

### Database Connections

To access the database e.g. from SQL Developer you configure the following properties:

Property | Value 
-------- | -----
Hostname | localhost
Port | 1521
SID | xe
Service | xe.local.com

The configured user with their credentials are:

User | Password 
-------- | -----
system | oracle
sys | oracle
 


## Backup

Complete the following steps to backup the data volume:

1. Stop the container with 

		docker stop oracle-jenkins
		
2. Backup the data volume to a compressed file ```xe.tar.gz``` in the current directory with a little help from the ubuntu image

		docker run --rm --volumes-from oracle-jenkins -v $(pwd):/backup ubuntu tar czvf /backup/oracle-jenkins.tar.gz /u01/app/oracle
		
3. Restart the container

		docker start oracle-jenkins


## Issues

Please file your bug reports, enhancement requests, questions and other support requests within [Github's issue tracker](https://help.github.com/articles/about-issues/): 

* [Existing issues](https://github.com/mritschel/docker-oracle12c-jenkins/issues)
* [submit new issue](https://github.com/mritschel/docker-oracle12c-jenkins/issues/new)

## License

docker-oracle12c-jenkins is licensed under the Apache License, Version 2.0. You may obtain a copy of the License at <http://www.apache.org/licenses/LICENSE-2.0>. 

See [Oracle Database Licensing Information User Manual](http://docs.oracle.com/database/121/DBLIC/editions.htm#DBLIC109) and [Oracle Database 12c Standard Edition 2](https://www.oracle.com/database/standard-edition-two/index.html) for further information.
