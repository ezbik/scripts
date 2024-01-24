#!/bin/bash
PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin
# vim: filetype=bash

# prereqs:
#    picocom
#    jq
#    yq

####### Conf start:
APN="internet"
####### Conf end

TTY_OPTS=,crnl
SOCAT_OPTS="-T5"
SOCAT="timeout -s 9 5 socat"
declare -A MODEMS_PREPARED

########## 

get_ifindex() {
    local DEV=$1
    case $DEV in
    *)              cat /sys/class/net/$DEV/ifindex 2>/dev/null | grep -oP '^\d+$' ;;
    esac
}

wwan_find_at_by_net() {
local DEV=$1
local EXTRA_PORT=0
    local KERNELS=$( 2>/dev/null udevadm info -a /sys/class/net/$DEV  |grep KERNELS | head -n1| cut -d\" -f2 )  # 2-1:1.12
    local DEVPATH_AT=/sys/bus/usb/devices/$( echo $KERNELS | rev | cut -d. -f2- | rev ).$EXTRA_PORT 
    local DEV_AT=$( 2>/dev/null basename $(ls --color=none  -d $DEVPATH_AT/tty/tty* 2>/dev/null | head -n1) )
    if [[ -n $DEV_AT ]] ; then DEV_AT=/dev/$DEV_AT; fi
test -e $DEV_AT && echo $DEV_AT 
}

wwan_get_single_info2() {
local DEV=$1
local CMDS=(
    AT+CGSN
    AT+CGMM
    AT+FMM
    AT+CFSN
    AT+CPIN?
    AT+CCID
    AT+CSQ
    AT+XLEC?
    AT+XCESQ?
    AT+COPS?
    AT+XCCINFO?
    AT+XREG?
    AT+CGDCONT?
    AT+CGCONTRDP  # may raise error!
    at+cgpiaf=1,0,0,0
    AT+CGPADDR
    'AT+XDATACHANNEL=2' # query USB<>data connection
    )

local AT_DEV=`wwan_find_at_by_net $DEV`
 
printf "%s\n" "${CMDS[@]}" | sendat.pl $AT_DEV 2>/dev/null | fromdos

}

=() { 
    local calc=$(echo "$@" | sed "s/,/./g" );
    echo "scale=10;$calc" | bc -l
}

_dump(){

local O=$(mktemp )

wwan_get_single_info2 $DEV  > $O

#cat $O

local AT_DEV=`wwan_find_at_by_net $DEV`

local IMEI=$(cat $O | grep -oP '^\d{15}$' )
local ICCID=$(cat $O | grep CCID: | awk '{print $2}'  )
local APN=$(cat $O | grep CGDCONT: | head -n1| cut -d, -f3 | sed 's@"@@g')

local CID=$( cat $O | grep XCCINFO: | head -n1| cut -d, -f4 | sed 's@"@@g' )
local LAC=$( cat $O | grep XCCINFO: | head -n1| cut -d, -f7| sed 's@"@@g' )

local rsrq_raw=$( cat $O | grep XCESQ: | cut -d, -f6 )
local rsrq=$( = "$rsrq_raw * 0.5 - 39" )

local rsrp=$( cat $O | grep XCESQ: | cut -d, -f7   )
if [[ $rsrp  -gt 0 ]] ; then rsrp=$((  -141 + $rsrp )); fi
local rssnr=$( cat $O | grep XCESQ: | cut -d, -f8 )

local rscp_raw=$( cat $O | grep XCESQ: | cut -d, -f4 )
local rscp=$( = "-120 + $rscp_raw" )

local ecno_raw=$( cat $O | grep XCESQ: | cut -d, -f5 )
local ecno=$( = "$ecno_raw*0.5 - 24 " )

local rssi=$( cat $O | grep  CSQ: | awk '{print $2}' | cut -d, -f1 )
if [[ $rssi -gt 0 ]] ; then rssi=$((  -113 + $rssi * 2 )) ; fi

local Bit_err_rate_perc=$( cat $O | grep  CSQ: | awk '{print $2}' | cut -d, -f2 )

local CELLOP
if grep -q 'COPS: 2' $O
then CELLOP=NO_SERVICE
else CELLOP=$( cat $O | grep  COPS: | cut -d, -f3 | sed 's@"@@g' )
fi

local MCCMNC=$( cat $O | grep -oP '(?<=XCCINFO: 0,)\d+,\d+' | sed 's@,@@' )

local XDATACHANNEL=$( cat $O | grep -oP '(?<=XDATACHANNEL: )\d' )
local WAN_NETMASK=$(cat $O | grep CGCONTRDP: | head -n1 | cut -d\" -f4| cut -d. -f5- )
local WAN_IP=$(cat $O | grep CGCONTRDP: | head -n1 | cut -d\" -f4| cut -d. -f1-4  )
local WAN_GW=$( cat $O | grep CGCONTRDP: | head -n1 | cut -d\" -f6  )
local WAN_DNS1=$( cat $O | grep CGCONTRDP: | head -n1 | cut -d\" -f8 )
local WAN_DNS2=$( cat $O | grep CGCONTRDP: | head -n1 | cut -d\" -f10 )

if [[ -z $WAN_DNS1 ]] && [[ -n $WAN_IP ]]
then WAN_DNS1=8.8.8.8
     WAN_DNS2=8.8.8.8
fi

local LOCAL_IP=$( ip -4 a s dev  $DEV 2>/dev/null  | grep 'scope global' | grep -oP '(?<=inet )\S+(?=/)' )

if [[ -n $WAN_IP ]] && [[ -n $LOCAL_IP ]]
then local DATA_CONNECTED="OK connected"
else local DATA_CONNECTED=no
fi

local WAN_IP6=$( cat $O | grep  CGPADDR: | head -n1 | cut -d\" -f4| grep -ioP '[:\w\d]+' )
local a=$( cat $O | grep "CGCONTRDP:.*FFFF" | head -n1  | cut -d\" -f4| cut -d\  -f2)
# it is FFFF:FFFF:FFFF:FFFF:0:0:0:0
case $( echo -n  $a | grep -o F | wc -l) in
12) local WAN_NETMASK6=48    ;;
16) local WAN_NETMASK6=64    ;;
20) local WAN_NETMASK6=80    ;;
24) local WAN_NETMASK6=96    ;;
28) local WAN_NETMASK6=112   ;;
esac

local BAND=$( cat $O | grep XREG:  | cut -d, -f3 )
local NET_TYPE=$( echo $BAND| cut -d_ -f2)


local SIGNAL
case $NET_TYPE in 
LTE)    SIGNAL="{ rssi: \"$rssi\", Bit_err_rate_perc: \"$Bit_err_rate_perc\", rsrp: \"$rsrp\", rsrq: \"$rsrq\", SINR: \"$rssnr\" }" ;;
INVALID|UMTS)   SIGNAL="{ rssi: \"$rssi\", Bit_err_rate_perc: \"$Bit_err_rate_perc\", rscp: \"$rscp\", ecno: \"$ecno\" }" ;;
esac

local XLEC=$( cat $O | grep XLEC: )
local i=$( echo $XLEC | cut -d, -f 2)
case $i in
0)  LTE_CA="no aggregation" ;;
1)  LTE_CA="single cell"    ;;
2|3|4|5) LTE_CA="$i cells"   ;;
esac


BWS=$(echo $XLEC| cut -d, -f3- | sed 's@,@ @g')
for i in $BWS
do
    case $i in
    2) inc=5 ;;
    3) inc=10;;
    4) inc=15 ;;
    5) inc=20 ;;
    *) inc=0 ;;
    esac
    totalBW=$(($totalBW+$inc))
done

#LTE_CA+="($XLEC)"
LTE_CA+=" bw=$totalBW"

local SIM_STATUS=$( cat $O | grep  CPIN: | awk '{print $2}'  )
if [[ -z $SIM_STATUS ]]
then SIM_STATUS=unknown_sim_status
fi

##debug:
#cp  $O /tmp/Fibocom_AT_dump.$$

local Y=`mktemp`
echo "
DEV: \"$DEV\"
AT_DEV: \"$AT_DEV\"
IMEI: \"$IMEI\"
ICCID: \"$ICCID\"
SIM_STATUS: \"$SIM_STATUS\"
SIGNAL: $SIGNAL
CELLOP: \"$CELLOP\"
NET_TYPE:   \"$NET_TYPE\"
BAND:   \"$BAND\"
LTE_CA: \"$LTE_CA\"
CID: \"$CID\"
LAC: \"$LAC\"
APN: \"$APN\"
DATA_CONNECTED: \"$DATA_CONNECTED\"
WAN_IP: \"$WAN_IP\"
WAN_GW: \"$WAN_GW\"
WAN_NETMASK:    \"$WAN_NETMASK\"
WAN_DNS1:  \"$WAN_DNS1\"
WAN_DNS2:  \"$WAN_DNS2\"
WAN_IP6: \"$WAN_IP6\"
WAN_NETMASK6: \"$WAN_NETMASK6\"
XDATACHANNEL: $XDATACHANNEL
MCCMNC: \"$MCCMNC\"
LOCAL_IP: \"$LOCAL_IP\"
" > $Y

cat $Y | yq . 

#cp $Y /tmp/Y

rm -f $Y  $O


}

is_wan_online() {
local AT_DEV=`wwan_find_at_by_net $DEV`
local O=`mktemp`
echo 'AT+CGCONTRDP' | sendat.pl $AT_DEV 2>/dev/null  | fromdos  >  $O
local E

if grep  -q 'CGCONTRDP:' $O
then  E=0
    #echo CGCONTRDP OK
else E=1
    #echo CGCONTRDP not OK
fi


rm $O
return $E
}

is_link_up(){
if ip li show  $DEV| grep -qE 'state UP'
then return 0
else return 1
fi
}

_data_on() {

echo "=>Data On"
echo "= checking if already online.."
if is_wan_online && is_link_up
then echo "= already online, no need to bring DATA on"
else
    echo "= not online, bring it online"

    local AT_DEV=`wwan_find_at_by_net $DEV`
    echo "= flush buffer from $AT_DEV"
    test -c "$AT_DEV" && timeout 1 cat  $AT_DEV >/dev/null
    local O=`mktemp`

    _dump > $O

    local APN


    if [[ -z $APN ]]
    then
        local CELLOP=$( cat $O | 2>/dev/null jq -r '.CELLOP //empty' )
        echo "= got CELLOP $CELLOP"

        if [[ -z $CELLOP ]]  || [[ $CELLOP == NO_SERVICE ]]
        then
            echo = will get APN by ICCID
            local ICCID=$( cat $O | 2>/dev/null jq -r '.ICCID //empty' )
            echo = got ICCID $ICCID
            APN=$(bash /usr/share/proxysmart/helpers/apn "$ICCID" 2>/dev/null)
        else
            APN=$(bash /usr/share/proxysmart/helpers/apn "$CELLOP" 2>/dev/null)
        fi
    fi

    APN=${APN:-internet}
    echo "= will use APN $APN"
    local APN_TYPE
    APN_TYPE=ip     #v4
    #APN_TYPE=IPV4V6 #v4 & v6

    local CMDS=(
        AT+CFUN=4
        AT+CGDCONT=2
        AT+CGDCONT=1
        AT+CGDCONT=0
        "AT+CGDCONT=0,\"$APN_TYPE\",\"$APN\""
        AT+XDNS=0,1
        AT+CGDCONT?
        'AT+XDATACHANNEL=1,1,"/USBCDC/0","/USBHS/NCM/0",2,0'
        AT+CFUN=1
        'AT+CGDATA=M-RAW_IP,0'  
    )

    printf "%s\n" "${CMDS[@]}" | 2>/dev/null sendat.pl $AT_DEV | fromdos


    local SL=3
    echo  = sleep $SL before getting CGATT status..
    sleep $SL
    echo = sleep end


    wait_CGATT || return 22

    local SL=3
    echo  = sleep $SL before getting WAN_IP..
    sleep $SL
    echo = sleep end

    res=fail
    for i in `seq 5`
    do
        echo = attempt $i
        if is_wan_online
        then  echo = connected
            res=OK
            break
        else sleep 2
        fi
    done
    [ "$res" == OK ] || { echo '= still not OK'; return 22; }
fi

_ifup

}

wait_CGATT() {
    local AT_DEV=`wwan_find_at_by_net $DEV`
    echo "= wait till connected AT+CGATT is 1"
    local O=`mktemp`
    local res="fail"
    for i in `seq 8`
    do
        echo = attempt $i
        # must return 1
        echo 'AT+CGATT?' | sendat.pl $AT_DEV | fromdos > $O
        if grep  -q 'CGATT: 1' $O
        then echo = CGATT connected
            res=OK
            break
        else    sleep 2
        fi 
    done
    rm $O
    [ "$res" == OK ] || { echo '= still not OK'; return 1; }
}

_data_off() {

echo "=>Data Off"
ip -4 a f dev $DEV
ip -6 a f dev $DEV


local CMDS=(
    AT
    AT+CFUN=4
    #AT+CGDCONT=1
    #AT+CGDCONT=0
    AT+CFUN=1
    AT+CFUN=1
    #AT+CGATT=0  # sometimes ip stays right after CFUN=1, we need to purge it.
                 # but then it will show NO_SERVICE in at+cops? !!

    # just disconnects data:
    #'AT+XDATACHANNEL=0,1,"/USBCDC/0","/USBHS/NCM/0",2,0'
)

local CMD
local AT_DEV=`wwan_find_at_by_net $DEV`

printf "%s\n" "${CMDS[@]}" | 2>/dev/null sendat.pl $AT_DEV | fromdos


}

_ifup() {

echo "= _IFUP"

I=$(mktemp)

echo "= getting current status"
_dump > $I

local WAN_GW=$( cat $I | 2>/dev/null jq -r '.WAN_GW //empty' )
local WAN_IP=$( cat $I | 2>/dev/null jq -r '.WAN_IP //empty' )
local WAN_NETMASK=$( cat $I | 2>/dev/null jq -r '.WAN_NETMASK //empty' )
local WAN_DNS1=$( cat $I | 2>/dev/null jq -r '.WAN_DNS1 //empty' )

local WAN_IP6=$( cat $I         | 2>/dev/null jq -r '.WAN_IP6 //empty' )
local WAN_NETMASK6=$( cat $I    | 2>/dev/null jq -r '.WAN_NETMASK6 //empty' ) 

rm -f $I

if [[ -n $WAN_GW ]] && [[ -n $WAN_IP ]] && [[ -n $WAN_NETMASK ]] && [[ -n $WAN_DNS1 ]] 
then
    echo "= DATA connected; WAN_IP $WAN_IP WAN_GW $WAN_GW"
    #set -x
    ip -4 a f dev $DEV
    ip -6 a f dev $DEV

    ifconfig $DEV $WAN_IP  netmask $WAN_NETMASK -arp
    METRIC=$(( $(get_ifindex $DEV) + 5000 ))
    ip ro rep default via $WAN_GW  dev $DEV  metric $METRIC

    ping -W2 -I$DEV -c2 1.1.1.1
    #curl -Ss -m2 -4 --interface $DEV ip.tanatos.org/ip.php

    if [[ -n $WAN_IP6 ]] && [[ -n $WAN_NETMASK6 ]]
    then
        ip -6 a a $WAN_IP6/$WAN_NETMASK6 dev $DEV
        ip -6 ro rep default via FE80::1 dev $DEV metric $METRIC
        #sleep 2
        #ping6 -W2 -I$DEV -c2 gmail.com
        #curl -Ss -m2 -6 --interface  $DEV ipv6.tanatos.org/ip.php
    fi

    #set +x
else
    echo "one of WAN_GW WAN_IP WAN_NETMASK WAN_DNS1 is empty, use data_on ; abort"
fi

}


_mode_3g() {
echo "=> Mode 3g"
local AT_DEV=`wwan_find_at_by_net $DEV`
echo "at+xact=1" | sendat.pl $AT_DEV 
}

_mode_4g() {
echo "=> Mode 4g"
local AT_DEV=`wwan_find_at_by_net $DEV`
echo "at+xact=2" | sendat.pl $AT_DEV
}

_mode_auto() {
echo "=> Mode Auto"
local AT_DEV=`wwan_find_at_by_net $DEV`
echo "at+xact=4,2" | sendat.pl $AT_DEV
}

_reset_ip() {
    echo "= Reset IP"

    _data_off

    local TARGET_MODE=$1
    case $TARGET_MODE in
    3g)     _mode_3g    ;;
    4g)     _mode_4g    ;;
    esac

    wait_CGATT || return 22
    _data_on
}

_reboot() {
echo "=> Reboot"
local AT_DEV=`wwan_find_at_by_net $DEV`
echo "at+cfun=15" | sendat.pl $AT_DEV
}


_list_sms() {
local AT_DEV=`wwan_find_at_by_net $DEV`
perl /usr/local/lib/list_sms.pl $AT_DEV 
}



_sms_send() {
local PHONE=$1
local TEXT="$2"
local AT_DEV=`wwan_find_at_by_net $DEV`
C=$( mktemp )

echo "
[gammu]

port = $AT_DEV
connection = at19200
synchronizetime = no
" > $C

echo "= sending {$TEXT} to $PHONE"
gammu -c $C --sendsms TEXT $PHONE  -unicode  -textutf8 "$TEXT" 

rm -f $C

}

_usage() {
if [ $# -lt 3 ]; then
    echo "Usage: $0 WWAN_IFACE <dump|reboot|3g|4g|auto|data_on|data_off|ifup|list_sms>"
    echo "       $0 WWAN_IFACE reset_ip [auto|3g|4g]"
    echo "                                          Reset IP (and stay in mode: optional)"
    echo "       $0 WWAN_IFACE sms_send PHONE 'te xt'"
    exit 1
fi
}


DEV=$1
ACTION=$2

    case $ACTION in
    reset_ip)   _reset_ip $3;;
    reboot)     _reboot ;;
    dump)       _dump ;;
    3g)         _mode_3g    ;;
    4g)         _mode_4g    ;;
    auto)       _mode_auto    ;;
    data_on)    _data_on    ;;
    data_off)   _data_off    ;;
    ifup)       _ifup    ;;
    list_sms)   _list_sms ;;
    sms_send)   _sms_send "$3" "$4" ;;
    sms_del)    _sms_del ;;
    *)          echo unknown call 
                _usage
                ;;
    esac


