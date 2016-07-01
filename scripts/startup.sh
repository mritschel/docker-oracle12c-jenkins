#!/bin/bash
set -e

echo "Starting jenkins on 8080"
java -jar /opt/jenkins.war

echo "Starting tnslsnr"
su oracle -c "/u01/app/oracle/product/12.1.0/xe/bin/lsnrctl start"

echo "Starting database"
su oracle -c 'echo startup\; | $ORACLE_HOME/bin/sqlplus -S / as sysdba'

echo "Starting web console on 9090"
su oracle -c 'echo EXEC DBMS_XDB.sethttpport\(9090"\)\; | $ORACLE_HOME/bin/sqlplus -S / as sysdba'

echo "Database init..."
for f in /entrypoint-initdb.d/*; do
    case "$f" in
        *.sh)  echo "$0: running $f"; . "$f" ;;
        *.sql) echo "$0: running $f"; su oracle -c "echo \@$f\; | $ORACLE_HOME/bin/sqlplus -S / as sysdba" ;;
        *)     echo "No volume sql script, ignoring $f" ;;
    esac
    echo
done
echo "End init."

echo "Starting Basenv"
su oracle -c '/u01/app/oracle/tvdtoolbox/dba/bin/oraup.ksh'
echo ""
echo "---------------------------------------------------------------------------"
echo "Oracle started Successfully!"
while true; do
    sleep 1m
done;