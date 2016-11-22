#!/bin/bash
##########################################################################
#  Author   M. Ritschel 
#           Trivadis GmbH Hamburg
#  Created: 28.09.2016 
#  Base-information 
#  ------------------------
# Startup-Script for the Trivadis Jenkins docker images
#  
##########################################################################
set -e
source $SCRIPTS_HOME/colorecho

echo_green "Set hostname for the listener..."
# Modify listener.ora  
STRSEARCH="<HOSTNAME>"
STRREPLACE=$HOSTNAME
find "$ORACLE_HOME/network/admin" -type f -name 'listener.ora' -print | while read i
do
   #cp "$i" "$i.tmp"
   if [ -f "$i.tmp" ]; then
      echo "s/$STRSEARCH/$STRREPLACE/g"
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

echo_green "Checking tnsnames.ora"
if [ -f "$ORACLE_HOME/network/admin/tnsnames.ora" ] 
then 
	echo "tnsnames.ora found." 
	rm -f $ORACLE_HOME/network/admin/tnsnames.ora
fi 
echo_green "Creating tnsnames.ora"  
printf "$ORACLE_SID = 
   (DESCRIPTION = 
      (ADDRESS = (PROTOCOL = TCP)
      (HOST = $HOSTNAME) 
      (PORT = 1521)) 
      (CONNECT_DATA = 
         (SERVICE_NAME = ${SERVICE_NAME})
      )
   )\n" > $ORACLE_HOME/network/admin/tnsnames.ora 
chown -R oracle:dba $ORACLE_HOME/network/admin/tnsnames.ora

alert_log="$ORACLE_BASE/diag/rdbms/$ORACLE_SID/$ORACLE_SID/trace/alert_$ORACLE_SID.log"
listener_log="$ORACLE_BASE/diag/tnslsnr/$HOSTNAME/listener/trace/listener.log"
pfile=$ORACLE_HOME/dbs/spfile$ORACLE_SID.ora

export PATH=$ORACLE_HOME/bin:$PATH

# monitor $logfile
monitor() {
    tail -F -n 0 $1 | while read line; do echo -e "$2: $line"; done
}
 
if [ "$1" = 'listener' ]; then
	trap "echo_red 'Caught SIGTERM signal, shutting down listener...'; lsnrctl stop" SIGTERM
	trap "echo_red 'Caught SIGINT signal, shutting down listener...'; lsnrctl stop" SIGINT
	monitor $listener_log listener &
	MON_LSNR_PID=$!
	lsnrctl start
	wait %1
elif [ "$1" = 'database' ]; then

	trap_db() {
		trap "echo_red 'Caught SIGTERM signal, shutting down...'; stop" SIGTERM;
		trap "echo_red 'Caught SIGINT signal, shutting down...'; stop" SIGINT;
	}  

	start_db() {
		echo_green "Starting listener..."
		monitor $listener_log listener &
		lsnrctl start | while read line; do echo -e "lsnrctl: $line"; done
		MON_LSNR_PID=$!		
		echo_green "Starting database..."
		trap_db
		monitor $alert_log alertlog &
		MON_ALERT_PID=$!
		sqlplus / as sysdba <<-EOF |
			pro Starting with pfile='$pfile' ...
			startup 
			exec dbms_xdb.sethttpport(8080);
			alter system register;
			exit 0
		EOF
		while read line; do echo -e "sqlplus: $line"; done
		wait $MON_ALERT_PID
		
	}

	stop() {
        trap '' SIGINT SIGTERM
		shu_immediate
		echo_green "Shutting down listener..."
		lsnrctl stop | while read line; do echo -e "lsnrctl: $line"; done
		kill $MON_ALERT_PID $MON_LSNR_PID
		exit 0
	}

	shu_immediate() {
		ps -ef | grep ora_pmon | grep -v grep > /dev/null && \
		echo_yellow "Shutting down the database..." && \
		sqlplus / as sysdba <<-EOF |
			set echo on
			shutdown immediate;
			exit 0
		EOF
		while read line; do echo -e "sqlplus: $line"; done
	}

	echo "Checking shared memory..."
	df -h | grep "Mounted on" && df -h | egrep --color "^.*/dev/shm" || echo "Shared memory is not mounted."
	[ -f $pfile ] && start_db

else
	exec "$@"
fi