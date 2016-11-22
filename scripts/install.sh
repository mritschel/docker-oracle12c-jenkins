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

# Check and create tnsnames.ora
echo "Checking tnsnames.ora"
if [ -f "${ORACLE_HOME}/network/admin/tnsnames.ora" ] 
then 
	echo "tnsnames.ora found." 
	rm -f $ORACLE_HOME/network/admin/tnsnames.ora
fi 
echo "Creating tnsnames.ora"  
printf "$ORACLE_SID = 
   (DESCRIPTION = 
      (ADDRESS = (PROTOCOL = TCP)
      (HOST = $HOSTNAME) 
      (PORT = 1521)) 
      (CONNECT_DATA = 
         (SERVICE_NAME = $SERVICE_NAME)
      )
   )\n" > $ORACLE_HOME/network/admin/tnsnames.ora 
chown -R oracle:dba $ORACLE_HOME/network/admin/tnsnames.ora
 
 
# create database
echo "create database $ORACLE_SID"
$ORACLE_HOME/bin/dbca -silent -createDatabase -templateName General_Purpose.dbc -gdbname xe.oracle.docker -sid xe -responseFile NO_VALUE -characterSet AL32UTF8 -totalMemory $DBCA_TOTAL_MEMORY -emConfiguration LOCAL -pdbAdminPassword oracle -sysPassword oracle -systemPassword oracle

# Apex remove Version 4.x and install Version 5.x

echo "Rremove old Apex Version" 
cd $ORACLE_HOME
echo -e "$ORACLE_HOME\n\n" | $ORACLE_HOME/bin/sqlplus -S / as sysdba @./apex/apxremov.sql > /dev/null

echo "Move the Apex 5.0.3 instalations Files to $ORACLE_HOME"
rm -fr $ORACLE_HOME/apex 
cp -r $INSTALL_HOME/apex $ORACLE_HOME 


echo "Install and Configuration Apex console"
echo -e "SYSAUX\n SYSAUX\n TEMP\n /i/" | $ORACLE_HOME/bin/sqlplus -S / as sysdba @apexins > /dev/null
echo -e "$ORACLE_HOME\n\n" | $ORACLE_HOME/bin/sqlplus -S / as sysdba @apxldimg $ORACLE_HOME > /dev/null
echo -e "ALTER USER ANONYMOUS ACCOUNT UNLOCK;" | $ORACLE_HOME/bin/sqlplus -S / as sysdba > /dev/null
echo -e "$ORACLE_HOME\n\n" | $ORACLE_HOME/bin/sqlplus -S / as sysdba @apxxepwd $APEX_PASS > /dev/null


echo "Set NAMES.DEFAULT_DOMAIN for the sqlnet..."
STRSEARCH="NAMES.DEFAULT_DOMAIN"
STRREPLACE="#NAMES.DEFAULT_DOMAIN"
find "$ORACLE_HOME/network/admin" -type f -name '*.ora' -print | while read i
do
   cp "$i" "$i.tmp"
   if [ -f "$i.tmp" ]; then
      #echo "s/$STRSEARCH/$STRREPLACE/g"
      sed "s/$STRSEARCH/$STRREPLACE/g" "$i" > "$i.new"
      if [ -f "$i.new" ]; then
          mv "$i.new" "$i"
      else
         echo "$i.new doesn't exist"
      fi
   else
      echo "$i.tmp wasn't created"
   fi
done

# Clearing
echo "Clearing"
rm -f /scripts/install.sh

