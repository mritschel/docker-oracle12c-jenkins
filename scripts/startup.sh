#!/bin/bash
set -e

# Add oracle to path
export PATH=${ORACLE_HOME}/bin:$PATH
if grep -q "PATH" ~/.bashrc
then
    echo "Found PATH definition in ~/.bashrc"
else
	echo "Extending PATH in in ~/.bashrc"
	printf "\nPATH=${PATH}\n" >> ~/.bashrc
fi

echo "Starting tnslsnr"
su oracle -c "${ORACLE_HOME}/bin/lsnrctl start"

echo "Starting database"
su oracle -c 'echo startup\; | $ORACLE_HOME/bin/sqlplus -S / as sysdba'

echo 'Starting web management console'
su oracle -c 'echo EXEC DBMS_XDB.sethttpport\(8080\)\; | ${ORACLE_HOME}/bin/sqlplus -s -l / as sysdba'
echo "Web management console initialized. Please visit"
echo "   - http://localhost:8080/em"
echo "   - http://localhost:8080/apex"

echo "Database init..."
for f in /entrypoint-initdb.d/*; do
    case "$f" in
        *.sh)  echo "$0: running $f"; . "$f" ;;
        *.sql) echo "$0: running $f"; su oracle -c "echo \@$f\; | ${ORACLE_HOME}/bin/sqlplus -S / as sysdba" ;;
        *)     echo "No volume sql script, ignoring $f" ;;
    esac
    echo
done

echo "Starting jenkins on 9090"
java -jar /opt/jenkins.war --httpPort=9090 > /tmp/jenkis.log 2>&1 &
echo "Jenkins console initialized. Please visit"
echo "   - http://localhost:9090"


echo "End init."
echo ""
echo "---------------------------------------------------------------------------"
echo "Oracle started Successfully !"
while true; do
    sleep 1m
done;