#!/bin/bash

set -e
source /scripts/colorecho

echo_yellow "Set hostname for the listener..."
# listener and tnsnames modify 
STRSEARCH="<HOSTNAME>"
STRREPLACE=$HOSTNAME
find "${ORACLE_HOME}/network/admin" -type f -name '*.ora' -print | while read i
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

alert_log="$ORACLE_BASE/diag/rdbms/$ORACLE_SID/$ORACLE_SID/trace/alert_$ORACLE_SID.log"
listener_log="$ORACLE_BASE/diag/tnslsnr/$HOSTNAME/listener/trace/listener.log"
pfile=$ORACLE_HOME/dbs/init$ORACLE_SID.ora

export PATH=${ORACLE_HOME}/bin:$PATH

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
		echo_yellow "Starting listener..."
		monitor $listener_log listener &
		lsnrctl start | while read line; do echo -e "lsnrctl: $line"; done
		MON_LSNR_PID=$!		
		echo_yellow "Starting database..."
		trap_db
		monitor $alert_log alertlog &
		MON_ALERT_PID=$!
		sqlplus / as sysdba <<-EOF |
			pro Starting with pfile='$pfile' ...
			startup pfile='$pfile';
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
		echo_yellow "Shutting down listener..."
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