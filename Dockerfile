##########################################################################
#  Author   M. Ritschel 
#           Trivadis GmbH Hamburg
#  Created: 10.03.2017 
#  Base-information 
#  ------------------------
# This Image based on https://hub.docker.com/r/mritschel/oracle12cr1_base/
#  
##########################################################################
FROM mritschel/oracle12cr1_base

MAINTAINER Martin.Ritschel@Trivadis.com

LABEL Basic oracle 12c.R1 with java and perl

# Environment
ENV JAVA_HOME /usr/lib/jvm/java-8-oracle
ENV JENKINS_HOME=$ORACLE_BASE/jenkins 
ENV SOFTWARE_HOME=./software
ENV SCRIPT_HOME=./scripts
ENV ORACLE_BASE=/u01/oracle
ENV ORACLE_HOME=/u01/oracle/product/12.1.0.2/dbhome_1
ENV INSTALL_DIR=$ORACLE_BASE/install
ENV ENTRY_FILE="entrypoint.sh"

# Fix sh
#RUN rm /bin/sh && ln -s /bin/bash /bin/sh

# Installing the required software 
USER root
RUN yum -y install unzip wget unzip zip gcc ksh sudo && \
    yum -y install java-1.7.0-openjdk-devel && \
    yum clean all
    
    
# Copy the installation files
COPY software/apex_5.0.3_1.zip $INSTALL_DIR/apex_5.0.3_1.zip
COPY software/apex_5.0.3_2.zip $INSTALL_DIR/apex_5.0.3_2.zip
COPY scripts/$ENTRY_FILE  $SCRIPT_DIR/$ENTRY_FILE 
COPY scripts/install.sh  $SCRIPT_DIR/install.sh 

RUN unzip $INSTALL_DIR/apex_5.0.3_1.zip -d $INSTALL_DIR >/dev/null 2>&1
RUN rm -f $INSTALL_DIR/apex_5.0.3_1.zip 
RUN unzip $INSTALL_DIR/apex_5.0.3_2.zip -d $INSTALL_DIR >/dev/null 2>&1
RUN rm -f $INSTALL_DIR/apex_5.0.3_2.zip 
RUN chmod -R 777 $INSTALL_DIR/*
RUN chown -R oracle:dba $INSTALL_DIR/* 
RUN chmod -R 777 $INSTALL_DIR/*
RUN chown -R oracle:dba $INSTALL_DIR/* 

# Install jenkins
VOLUME ["/jenkins"]
RUN mkdir $JENKINS_HOME
ADD software/jenkins.war $JENKINS_HOME/jenkins.war 
RUN chown -R oracle:dba $JENKINS_HOME 
RUN chmod -R 777 $JENKINS_HOME 


# start the installation scripts
USER oracle
# RUN $SCRIPT_HOME/install.sh


# Ports  
EXPOSE 9090

# Startup script to start the database in container
# ENTRYPOINT ["/u01/app/oracle/scripts/entrypoint.sh"]

 

