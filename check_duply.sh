#!/bin/bash

# This script is used to parse backupninja log and can be easily connected to Nagios or NRPE 
# Author Pavel Piatruk 
# Jun, 2015

LOG=/var/log/duply.status
CODE=0
LOCKFILE=/root/.cache/duplicity/duply_mys3/lockfile.lock

if    test -f $LOCKFILE && pgrep -f duply.run > /dev/null
then    TXT="PENDING duply is running"
        CODE=0
elif test -d /etc/duply && ! ls /etc/duply &>/dev/null
then    TXT="unable to read conf dir"
        CODE=2
elif ! find /etc/duply/*/conf 2>/dev/null | grep -q .
then    TXT="no conf found"
        CODE=0
elif ! test -f $LOG 
then	TXT="$LOG doesnt exist"
	CODE=1
elif  [ "`stat -c %Y $LOG`" -lt "`date +%s -d -1day-12hour`" ]
then    TXT="$LOG modification time is too old ["$(date -d@$(stat -c %Y $LOG) +"%F %T")"]"
	CODE=1
elif    test -f $LOCKFILE && ! pgrep -f duply.run > /dev/null
then    TXT="lockfile $LOCKFILE exists but no process running"
        CODE=2
elif  ! test -f $LOCKFILE && grep -q "FAIL" $LOG
then	TXT="last backup had fatals or errors, review /var/log/duply.log"
	CODE=2
elif  grep -q "OK" $LOG 
then	TXT="looks good ["$(date +%F-%T -d@$(stat -c %Y /var/log/duply.status ))"]"
	CODE=0
else	TXT="Unknown, review /var/log/duply.log"
	CODE=1
fi

case $CODE in
0)	TXT="OK $TXT" ;;
1)	TXT="WARNING $TXT" ;;
2)	TXT="CRITICAL $TXT" ;;
esac

echo "DUPLY $TXT"
exit $CODE
