#!/bin/bash
##########################################################################
#  Author   M. Ritschel 
#           Trivadis GmbH Hamburg
#  Created: 22.11.2016 
#  Base-information 
#  ------------------------
# Installation-Script for the Trivadis docker images
#  
##########################################################################
set -e


# Read Hostname
HOSTNAME=$(cat /etc/hostname)

export ORACLE_SID=$ORACLE_SID

echo "Apex update to  Version 5.x"

echo "Move the Apex 5.0.3 instalations Files to $ORACLE_HOME"
rm -fr $ORACLE_HOME/apex 
cp -r $INSTALL_DIR/apex $ORACLE_HOME 

echo "Install and Configuration Apex console"
cd $ORACLE_HOME/apex 
echo -e "SYSAUX\n SYSAUX\n TEMP\n /i/" | $ORACLE_HOME/bin/sqlplus -S / as sysdba @apexins 

echo "Install Apex (apxldimg)"
echo -e "\n" | $ORACLE_HOME/bin/sqlplus -S / as sysdba @apxldimg $ORACLE_HOME  

echo "ALTER USER ANONYMOUS"
echo -e "ALTER USER ANONYMOUS ACCOUNT UNLOCK;\n" | $ORACLE_HOME/bin/sqlplus -S / as sysdba  

echo "Change Apex Password (apxxepwd)"
echo -e "\n" | $ORACLE_HOME/bin/sqlplus -S / as sysdba @$SCRIPTS_HOME/upd_apexpwd.sql  
 
echo "Set Apex Port"
echo -e "EXEC DBMS_XDB.sethttpport(8080);\n\n" | $ORACLE_HOME/bin/sqlplus -S / as sysdba  

# Clearing
echo "Clearing"
rm -f $INSTALL_DIR/install.sh

