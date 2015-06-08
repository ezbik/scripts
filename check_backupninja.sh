#!/bin/bash

# This script is used to parse backupninja log and can be easily connected to Nagios or NRPE 
# Author Pavel Piatruk 
# Jun, 2015

LOG=/var/log/backupninja.log
CODE=0

if ! test -f $LOG 
then	TXT="$LOG doesnt exist"
	CODE=1
elif  [ "`stat -c %Y $LOG`" -lt "`date +%s -d -1day-12hour`" ]
then	TXT="$LOG modification time is too old"
	CODE=1
elif  ! grep -q "FINISHED:" $LOG 
then	TXT="No finished backups"
	CODE=0
elif  grep FINISHED: $LOG | tail -n1 | grep -P '\b[1-9](\d+)? (fatal|error)' -q
then	TXT="last backup had fatals or errors"
	CODE=2
elif  grep FINISHED: $LOG | tail -n1 | grep -P '\b[1-9](\d+)? (warning)' -q
then	TXT="last backup had warnings"
	CODE=1
elif grep FINISHED: $LOG | tail -n1 | grep "0 fatal. 0 error. 0 warning." -q
then	TXT="looks good"
else	TXT="Unknown"
	CODE=1
fi

case $CODE in
0)	TXT="OK $TXT" ;;
1)	TXT="WARNING $TXT" ;;
2)	TXT="CRITICAL$TXT" ;;
esac

echo "BACKUPNINJA $TXT"
exit $CODE
