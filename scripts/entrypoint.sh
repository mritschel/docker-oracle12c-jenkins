#!/bin/bash
set -e

source /scripts/colorecho

# Add oracle to path
export PATH=${ORACLE_HOME}/bin:$PATH
if grep -q "PATH" ~/.bashrc
then
    echo "Found PATH definition in ~/.bashrc"
else
	echo "Extending PATH in in ~/.bashrc"
	printf "\nPATH=${PATH}\n" >> ~/.bashrc
fi

echo_yellow "Starting jenkins on 9090"
echo_yellow "---------------------------------------------------------------------------"
java -jar /opt/jenkins.war --httpPort=9090 > /var/log/jenkis.log 2>&1 &
echo_yellow "Jenkins console initialized. Please visit"
echo_yellow "   - http://localhost:9090"
echo_yellow "\n"
echo_yellow "Jenkins initial setup is required. An admin user has been created and a password generated."
echo_yellow "This may also be found at: /jenkins/secrets/initialAdminPassword"
echo_yellow "\n"
echo_yellow "---------------------------------------------------------------------------"
echo "\n \n \n"
echo_yellow  "Starting listener and database"
echo_yellow "---------------------------------------------------------------------------"
su oracle -c '/scripts/startup.sh database'
echo_yellow "Database and Web management console initialized. Please visit"
echo_yellow "   - http://localhost:8080/em"
echo_yellow "   - http://localhost:8080/apex"
echo_yellow "\n"
echo_yellow "---------------------------------------------------------------------------"
