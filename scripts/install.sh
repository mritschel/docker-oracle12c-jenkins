#!/bin/bash
set -e
mkdir -p /entrypoint-initdb.d
# Prevent owner issues on mounted folders
chown -R oracle:dba /u01/app/oracle
rm -f /u01/app/oracle/product
ln -s /u01/app/oracle-product /u01/app/oracle/product

#Run Oracle root scripts
/u01/app/oraInventory/orainstRoot.sh > /dev/null 2>&1
echo | /u01/app/oracle/product/12.1.0/xe/root.sh > /dev/null 2>&1 || true

# Read Hostname
HOSTNAME=$(cat /etc/hostname)

# Create tnsnames.ora
if [ -f "${ORACLE_HOME}/network/admin/tnsnames.ora" ] 
then 
	echo "tnsnames.ora found." 
else 
	echo "Creating tnsnames.ora"  
	printf "${ORACLE_SID} =\n\ 
	(DESCRIPTION =\n\ 
	 (ADDRESS = (PROTOCOL = TCP)(HOST = ${HOSTNAME})(PORT = 1521))\n\ 
	 (CONNECT_DATA = (SERVICE_NAME = ${SERVICE_NAME})))\n" > ${ORACLE_HOME}/network/admin/tnsnames.ora 
fi 

echo "Initializing database."
mv /u01/app/oracle-product/12.1.0/xe/dbs /u01/app/oracle/dbs
ln -s /u01/app/oracle/dbs /u01/app/oracle-product/12.1.0/xe/dbs

#create DB for SID: xe
su oracle -c "$ORACLE_HOME/bin/dbca -silent -createDatabase -templateName General_Purpose.dbc -gdbname xe.oracle.docker -sid xe -responseFile NO_VALUE -characterSet AL32UTF8 -totalMemory $DBCA_TOTAL_MEMORY -emConfiguration LOCAL -pdbAdminPassword oracle -sysPassword oracle -systemPassword oracle"

# Basenv Installation
#su oracle -c "$INSTALL_HOME/tvdtoolbox/runInstaller -responseFile $INSTALL_HOME/basenv_install.rsp -silent"

#config Apex console
echo "Configuring Apex console"
cd $ORACLE_HOME/apex
su oracle -c 'echo -e "${PASS}$\n9090" | $ORACLE_HOME/bin/sqlplus -S / as sysdba @apxconf > /dev/null'
su oracle -c 'echo -e "${ORACLE_HOME}\n\n" | $ORACLE_HOME/bin/sqlplus -S / as sysdba @apex_epg_config_core.sql > /dev/null'
su oracle -c 'echo -e "ALTER USER ANONYMOUS ACCOUNT UNLOCK;" | $ORACLE_HOME/bin/sqlplus -S / as sysdba > /dev/null'

rm /scripts/install.sh