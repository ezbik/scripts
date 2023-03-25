#!/bin/bash

# Author: Pavel Piatruk
# API reference: https://developers.linode.com/v4/reference/linode

[ -z "$API" ] && { echo "API variable is empty. Pls set it."; exit 2; }

function get_linodeid_by_name() {
local LABEL=$1
if echo $LABEL | grep -Pq '^\d+$'
then
    echo $LABEL 

else

    LABEL=$( echo $LABEL | cut -d.  -f1 )

    curl -Ss "https://api.linode.com/?api_key=$API&api_action=linode.list"|  json_xs  -e ' foreach my $e ((@{$_->{"DATA"}})) { if ($e->{LABEL} eq "'$LABEL'") { print $e->{LINODEID},"\n" } }; $_=undef;  ' -t string 

fi

}



function get_diskid_by_linodeid() {

local LINODEID=$1
curl -Ss "https://api.linode.com/?api_key=$API&api_action=linode.disk.list&LinodeID=$LINODEID" | json_xs -e ' foreach my $e ((@{$_->{"DATA"}})) { if ($e->{TYPE} eq "ext4") { print $e->{DISKID},"\n" } }; $_=undef;  ' -t string

}


function shrink_disk() {


local LINODEID=$1
local DISKID=$2
local SIZE=18000
curl -Ss "https://api.linode.com/?api_key=$API&api_action=linode.disk.resize&DiskID=$DISKID&LinodeID=$LINODEID&size=$SIZE" | json_pp

echo $@ | grep -q wait=1 && wait_for_jobs $LINODEID
}

function plan_change() {


local LINODEID=$1
local PLANID=1
curl -Ss "https://api.linode.com/?api_key=$API&api_action=linode.resize&PlanID=$PLANID&LinodeID=$LINODEID" | json_pp

echo $@ | grep -q wait=1 && wait_for_jobs $LINODEID

}

function boot() {

local LINODEID=$( get_linodeid_by_name $1 )
curl -Ss "https://api.linode.com/?api_key=$API&api_action=linode.boot&LinodeID=$LINODEID" | json_pp

echo $@ | grep -q wait=1 && wait_for_jobs $LINODEID

}


function shutdown() {

local LINODEID=$( get_linodeid_by_name $1 )
curl -Ss "https://api.linode.com/?api_key=$API&api_action=linode.shutdown&LinodeID=$LINODEID" | json_pp

echo $@ | grep -q wait=1 && wait_for_jobs $LINODEID
}

function reboot () {

local LINODEID=$( get_linodeid_by_name $1 )
curl -Ss "https://api.linode.com/?api_key=$API&api_action=linode.reboot&LinodeID=$LINODEID" | json_pp

echo $@ | grep -q wait=1 && wait_for_jobs $LINODEID

}



function get_pending_jobs() {

local LINODEID=$1
curl -Ss "https://api.linode.com/?api_key=$API&api_action=linode.job.list&LinodeID=$LINODEID&pendingOnly=1" |  json_xs -e ' print scalar( @{$_->{"DATA"}}) ,"\n" ; $_=undef;  ' -t string

}


function wait_for_jobs() {

local LINODEID=$( get_linodeid_by_name $1 )

while :; 
do 
    if [[  $( get_pending_jobs $LINODEID ) -gt 0 ]] ; 
    then 
        echo wait; 
        sleep 6;
    else break; 
    fi; 
done

}

get_ip() {

local LINODEID=$( get_linodeid_by_name $1 )
curl -Ss "https://api.linode.com/?api_key=$API&api_action=linode.ip.list&LinodeID=$LINODEID"|  json_xs  -e ' 
    foreach my $e ((@{$_->{"DATA"}}))  { print $e->{IPADDRESS},"\n" } ; $_=undef;  
        ' -t string 

}

list_ips() {

curl -Ss "https://api.linode.com/?api_key=$API&api_action=linode.ip.list"|  json_xs  -e ' 
    foreach my $e ((@{$_->{"DATA"}}))  { print $e->{LINODEID},"\t",$e->{IPADDRESS},"\n" } ; $_=undef;  
        ' -t string 

}

list() {

curl -Ss "https://api.linode.com/?api_key=$API&api_action=linode.list"|  json_xs  -e ' 
    foreach my $e ((@{$_->{"DATA"}}))  { print $e->{LINODEID},"\t",$e->{LABEL},"\n" } ; $_=undef;  
        ' -t string 

}


get_large_cache_servers() {

curl -Ss "https://api.linode.com/?api_key=$API&api_action=linode.list"|  json_xs  -e ' foreach my $e ((@{$_->{"DATA"}}))  { print $e->{LABEL},":",$e->{PLANID},"\n" } ; $_=undef;  ' -t string | grep ^cache | grep -v 1$ | cut -d: -f1 | sed 's/$/.rmkr.net/' | sort

}

get_datacenter() {

local LINODEID=$( get_linodeid_by_name $1 )

local DATACENTERID=$(    curl -Ss "https://api.linode.com/?api_key=$API&api_action=linode.list"|  json_xs  -e ' foreach my $e ((@{$_->{"DATA"}})) { if ($e->{LINODEID} eq "'$LINODEID'") { print $e->{DATACENTERID},"\n" } }; $_=undef;  ' -t string )


curl -Ss "https://api.linode.com/?api_key=$API&api_action=avail.datacenters"|  json_xs  -e ' foreach my $e ((@{$_->{"DATA"}})) { if ($e->{DATACENTERID} eq "'$DATACENTERID'") { print $e->{ABBR},"\n" } }; $_=undef;  ' -t string 


}

get_lish_cmd() {

local LABEL=$1
LABEL=$( echo $LABEL | cut -d.  -f1 )

## well it is better to detect the correct datacenter. but it will also work if you connect to the default one

#local DC=$( get_datacenter $LABEL )
local DC=newark
echo "ssh -t $LINODE_USER@lish-$DC.linode.com $LABEL"




}

downgrade_complete() {

H=$1

LINODEID=$( get_linodeid_by_name $H)
echo "=got LINODEID $LINODEID"
echo "=shutdown $LINODEID"
shutdown $LINODEID wait=1
DISKID=$( get_diskid_by_linodeid $LINODEID)
echo "=got DISKID $DISKID"
echo "=shrink disk $DISKID on $LINODEID"
shrink_disk $LINODEID $DISKID wait=1
echo "=plan change of $LINODEID"
plan_change $LINODEID wait=1
echo "=boot $LINODEID"
boot $LINODEID wait=1

}


reboot_to_rescue() {


# https://developers.linode.com/v4/reference/endpoints/linode/instances/$id/rescue

[ -z "$TOKEN" ] && { echo "empty token, get one at https://cloud.linode.com/profile/tokens" ; exit 2; }

local LINODEID=$( get_linodeid_by_name $1)
local DISKID=$( get_diskid_by_linodeid $LINODEID )


curl -H "Content-Type: application/json" \
    -H "Authorization: Bearer $TOKEN" \
    -X POST -d '{
        "devices": {
          "sdb": {"disk_id": '$DISKID'}
        }
    }' \
    https://api.linode.com/v4/linode/instances/$LINODEID/rescue
echo

echo $@ | grep -q wait=1 && wait_for_jobs $LINODEID
get_lish_cmd $1
}


showstatus () {


local LABEL=$( echo $1  | cut -d.  -f1 )

linode-linode --api-key $API -a show --label $LABEL


}



usage() {

    echo "usage:
    get_linodeid_by_name    LABEL|HOSTNAME
    boot            LINODEID|LABEL|HOSTNAME    [wait=1]
    shutdown        LINODEID|LABEL|HOSTNAME    [wait=1]
    reboot          LINODEID|LABEL|HOSTNAME    [wait=1]
    downgrade_complete HOSTNAME 
    get_large_cache_servers
    list_ips                        # return list of LINODEID\\tIPADDRESS
    list                            # return list of LINODEID\\tLABEL
    get_ip          LINODEID|LABEL|HOSTNAME
    get_datacenter  LINODEID|LABEL|HOSTNAME
    get_lish_cmd    LABEL|HOSTNAME
    reboot_to_rescue    LINODEID|LABEL|HOSTNAME
    wait_for_jobs       LINODEID|LABEL|HOSTNAME
    showstatus          LABEL
"

}


ACTION=$1
shift

case $ACTION in
downgrade_complete|get_large_cache_servers|get_linodeid_by_name|boot|shutdown|list_ips|list|get_ip|reboot|get_datacenter|get_lish_cmd|reboot_to_rescue|wait_for_jobs|showstatus)
        $ACTION $@
        ;;
*)      #echo wrong option
        usage
        ;;
esac

