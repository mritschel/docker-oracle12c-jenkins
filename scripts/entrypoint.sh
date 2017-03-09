#!/bin/bash
##########################################################################
#  Author   M. Ritschel 
#           Trivadis GmbH Hamburg
#  Created: 22.11.2016 
#  Base-information 
#  ------------------------
# Entry-Script for the Trivadis docker images
#  
##########################################################################
set -e

source $SCRIPT_DIR/colorecho

# Add oracle to path
export PATH=$ORACLE_HOME/bin:$PATH
if grep -q "PATH" ~/.bashrc
then
    echo "Found PATH definition in ~/.bashrc"
else
	echo "Extending PATH in in ~/.bashrc"
	printf "\nPATH=${PATH}\n" >> ~/.bashrc
fi

# Check if the script install.sh is present 
if [ -f $SCRIPT_DIR/$ENTRY_FILE ]
  then
    $SCRIPT_DIR/install.sh
fi

"
java -jar $JENKINS_HOME/jenkins.war --httpPort=9090 > $JENKINS_HOME/jenkis.log 2>&1 &
echo_green "#########################################################################"
echo_green "Jenkins console initialized. Please visit"
echo_green "   - http://localhost:9090"
echo_green "#########################################################################"
