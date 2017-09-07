#!/bin/bash

# This script is used to parse backupninja log and can be easily connected to Nagios or NRPE 
# Author Pavel Piatruk 
# Jun, 2015

LOG=/var/log/backupninja.log
CODE=0

cat_logs() {
zcat  $LOG.1.gz     2>/dev/null
cat $LOG            2>/dev/null
}

if test -d /etc/backup.d/ && ! ls /etc/backup.d/ &>/dev/null
then    TXT="unable to read conf dir"
        CODE=2
elif ! find /etc/backup.d/*dup 2>/dev/null | grep -q .
then    TXT="no conf found"
        CODE=0
elif ! test -f $LOG 
then	TXT="$LOG doesnt exist"
	CODE=0
elif  [ "`stat -c %Y $LOG`" -lt "`date +%s -d -1day-12hour`" ]
then	TXT="$LOG modification time is too old"
	CODE=1
elif  ! cat_logs | grep -q "FINISHED:"
then	TXT="No finished backups"
	CODE=0
elif  cat_logs | grep FINISHED: | tail -n1 | grep -P '\b[1-9](\d+)? (fatal|error)' -q
then	TXT="last backup had fatals or errors"
	CODE=2
elif  cat_logs | grep FINISHED: | tail -n1 | grep -P '\b[1-9](\d+)? (warning)' -q
then	TXT="last backup had warnings"
	CODE=1
else    
        LAST_TIMESTAMP=$( cat_logs |  tail -n 100 | grep -v Skipping | grep -Po '^.*\d\d:\d\d\:\d\d' | uniq  | tail -n1 )
        if cat_logs | grep "$LAST_TIMESTAMP" | grep -q Fatal
        then    TXT="last backup had fatals"
                CODE=2
        elif cat_logs | grep "$LAST_TIMESTAMP" | grep -q -P "FINISHED: .*0 fatal. 0 error. 0 warning." 
        then	TXT="looks good ($LAST_TIMESTAMP)"
        elif    pgrep  backupninja >/dev/null
        then    TXT="pending, running now"
        else    TXT="unknown"
	        CODE=1
        fi
fi

case $CODE in
0)	TXT="OK $TXT" ;;
1)	TXT="WARNING $TXT" ;;
2)	TXT="CRITICAL $TXT" ;;
esac

echo "BACKUPNINJA $TXT"
exit $CODE
