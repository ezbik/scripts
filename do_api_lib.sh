#!/bin/bash

if [ -z "$BASH" ]
then	echo run me with Bash
	exit
fi

[ -z "$DO_TOKEN" ] && echo "DO_TOKEN variable empty, export it" && exit

# prepare file like this

#export DO_TOKEN=0f638f36
#function doctl () { /usr/local/bin/doctl --access-token $DO_TOKEN $* } 
#export -f doctl

##
CACHE_PREFIX=$( echo $DO_TOKEN|cut -b1-4 )

WAIT=$(echo "$@" | grep wait=1 -q &&  echo 1 )

###########################################################
function do_power_on {
local DROPLET_ID=$( do_get_id $1)
local TMP=$(mktemp)
#echo "==DO:got droplet ID=$DROPLET_ID"
[ -n "$DROPLET_ID" ] || exit 2
#echo "==DO:power_on droplet by id $DROPLET_ID"
#echo "== calling DO"
# V2:
curl -Ss -X POST   "https://api.digitalocean.com/v2/droplets/$DROPLET_ID/actions" -H "Authorization: Bearer $DO_TOKEN" -d'{"type":"power_on"}'  -H "Content-Type: application/json" | tee $TMP

local ACTION_ID=$( cat $TMP| python -c 'import json,sys;obj=json.load(sys.stdin);print obj["action"]["id"]' 2>/dev/null )

# V1:

echo
rm $TMP
[ "$WAIT" == 1 ] && [ -n "$ACTION_ID" ] && do_wait_for_action $DROPLET_ID $ACTION_ID
}

################################
function do_power_off {
local DROPLET_ID=$( do_get_id $1)
local TMP=$(mktemp)

[ -n "$DROPLET_ID" ] || exit 2

curl -Ss -X POST   "https://api.digitalocean.com/v2/droplets/$DROPLET_ID/actions" -H "Authorization: Bearer $DO_TOKEN"  -d'{"type":"power_off"}'  -H "Content-Type: application/json" | tee $TMP


echo
local ACTION_ID=$( cat $TMP| python -c 'import json,sys;obj=json.load(sys.stdin);print obj["action"]["id"]' 2>/dev/null )
rm $TMP
[ "$WAIT" == 1 ] && [ -n "$ACTION_ID" ] && do_wait_for_action $DROPLET_ID $ACTION_ID
}

#################################################

function do_power_cycle {
# reboots container by hostname

DROPLET_ID=$( do_get_id $1)
echo "==DO:got droplet ID=$DROPLET_ID"
local TMP=$(mktemp)
[ -n "$DROPLET_ID" ] || exit 2

curl -Ss -X POST   "https://api.digitalocean.com/v2/droplets/$DROPLET_ID/actions" -H "Authorization: Bearer $DO_TOKEN"  -d'{"type":"power_cycle"}'  -H "Content-Type: application/json" | tee $TMP

echo
local ACTION_ID=$( cat $TMP| python -c 'import json,sys;obj=json.load(sys.stdin);print obj["action"]["id"]' 2>/dev/null )
rm $TMP
[ "$WAIT" == 1 ] && [ -n "$ACTION_ID" ] && do_wait_for_action $DROPLET_ID $ACTION_ID


}
##############################


do_list_droplets() {

doctl compute droplet list 

}


#do_list_droplets () {
#
#local DO_LIST=~/.cache/do_list.$CACHE_PREFIX
#
#
#{
#
#TOTAL=$( curl -Ss -X GET  "https://api.digitalocean.com/v2/droplets?per_page=100" -H "Authorization: Bearer $DO_TOKEN" | perl -MJSON=from_json -e '@a=<STDIN>; print from_json(join("",@a))->{meta}->{total}' )
#
#
#PER_PAGE=180
#
#for PAGE in $(seq 1 $((1+$TOTAL/$PER_PAGE)) )
#do
#
#J=~/.cache/do_list.$CACHE_PREFIX.$PAGE.json
#
#curl -Ss -X GET  "https://api.digitalocean.com/v2/droplets?per_page=$PER_PAGE&page=$PAGE" -H "Authorization: Bearer $DO_TOKEN" | json_pp | tee $J | perl -MJSON=from_json -e '@a=<STDIN>; my $h=from_json(join("",@a))->{"droplets"}; foreach $e (@{$h}) {if (! $e->{kernel}->{name}) { $e->{kernel}->{name}="internal"}; print  join("\t", $e->{id}, $e->{region}->{slug},  $e->{kernel}->{name} ,  $e->{name}    ), "\n"}'  
#
#done
#
#
#} | tee $DO_LIST
#
#
#
#}



###########################
function do_get_id {
# gets id by hostname ; from DO

local SERVER=$1
[ -n "$SERVER" ] || exit 2

if echo $SERVER | grep -Pq '^\d+$'
then
        echo $SERVER

else
        doctl compute droplet list |  awk  '{if ($2 == '\"$SERVER\"') print $1}'

#curl -Ss -X GET  "https://api.digitalocean.com/v2/droplets?per_page=1000" -H "Authorization: Bearer $DO_TOKEN" | perl -MJSON=from_json -e '@a=<STDIN>; my $h=from_json(join("",@a))->{"droplets"}; foreach $e (@{$h}) {print  $e->{id},"=",$e->{name},"\n"}' | grep "=$SERVER$" |cut -d= -f1 
#do_list_droplets  | awk -F "\t" '{if ($4 == '\"$SERVER\"') print $1}'  



#DO_DB_LOCAL=~/.cache/do.json.$CACHE_PREFIX

#find $DO_DB_LOCAL -type f -cmin -60 -size +2000c | grep -q . || { 
        ##refreshing $DO_DB_LOCAL"  
        #curl https://support.wsynth.net/sys/core/do-data.php?key=Kt4AO1s73w0m2zpQzYt9r6TkiyiDPutF -H "Host: st.support.wsynth.net" -Ss  -k > $DO_DB_LOCAL ; 
#}

 #cat $DO_DB_LOCAL | json_xs  -e ' foreach my $e ((@{$_})) { if ($e->{name} eq "'"$SERVER"'") { print $e->{id},"\n" } }; $_=undef;  ' -t string


fi

}

###########################


do_get_action_status () {

local DROPLET_ID=$( do_get_id $1)
local ACTION_ID=$2

curl -Ss -X GET "https://api.digitalocean.com/v2/droplets/$DROPLET_ID/actions/$ACTION_ID" -H "Authorization: Bearer $DO_TOKEN"  

}

################################
do_list_available_kernels () {

DROPLET_ID=1225956
curl -Ss -X GET "https://api.digitalocean.com/v2/droplets/$DROPLET_ID/kernels?per_page=200"  \
        -H "Authorization: Bearer $DO_TOKEN" | \
        perl -MJSON=from_json -e '@a=<STDIN>; my $h=from_json(join("",@a))->{"kernels"}; foreach $e (@{$h}) {print  join("\t\t", $e->{id}, $e->{name},  $e->{version}    ), "\n"}'

}

################################



do_change_kernel () {

local DROPLET_ID=$( do_get_id $1)
local KERNEL_ID=$2

local TMP=$(mktemp)

curl -Ss -X POST "https://api.digitalocean.com/v2/droplets/$DROPLET_ID/actions" -d '{"type":"change_kernel","kernel":'$KERNEL_ID'}' -H "Authorization: Bearer $DO_TOKEN"   -H "Content-Type: application/json" | tee $TMP
echo
local ACTION_ID=$( cat $TMP| python -c 'import json,sys;obj=json.load(sys.stdin);print obj["action"]["id"]' 2>/dev/null )
#echo ACTION_ID=$ACTION_ID
rm $TMP
[ "$WAIT" == 1 ] && [ -n "$ACTION_ID" ] && do_wait_for_action $DROPLET_ID $ACTION_ID

}
##############################

do_destroy () {

local DROPLET_ID=$( do_get_id $1)
echo "== destroying $DROPLET_ID"

local TMP=$(mktemp)

curl -v -Ss -X DELETE -H "Content-Type: application/json" -H "Authorization: Bearer $DO_TOKEN" "https://api.digitalocean.com/v2/droplets/$DROPLET_ID" 
echo
rm $TMP

}
##############################

do_create_droplet () {


local TMP=$(mktemp)
#local REGION=sgp1
#local NAME=pavel-test-eee$$.com
#local SIZE=512mb
#local IMAGE=ubuntu-14-04-x64

local REGION=$(  echo ${BASH_ARGV[*]}  | grep -P "\bregion=\S+\b" -o | cut -d= -f2  )
local NAME=$(  echo ${BASH_ARGV[*]}  | grep -P "\bname=\S+\b" -o | cut -d= -f2  )
local SIZE=$(  echo ${BASH_ARGV[*]}  | grep -P "\bsize=\S+\b" -o | cut -d= -f2  )
local IMAGE=$(  echo ${BASH_ARGV[*]}  | grep -P "\bimage=\S+\b" -o | cut -d= -f2  )


curl -Ss -X POST "https://api.digitalocean.com/v2/droplets" -d \
        '{"name":"'$NAME'","region":"'$REGION'","size":"'$SIZE'","image":"'$IMAGE'","ssh_keys":["0f:95:bc:f1:84:9f:ee:b1:cc:1b:ea:9c:51:01:18:9d"],"backups":false,"ipv6":true,"user_data":null,"private_networking":null,"volumes": null}'  \
        -H "Authorization: Bearer $DO_TOKEN"   -H "Content-Type: application/json" | tee $TMP

local ACTION_ID=$( cat $TMP|  json_xs  -e 'use Data::Dumper;   foreach my $e ( @{$_->{links}->{actions}}  ) { if ($e->{rel} == "create" ) { print $e->{id},"\n" }} ; $_=undef;  ' -t string )
local DROPLET_ID=$( cat $TMP| python -c 'import json,sys;obj=json.load(sys.stdin);print obj["droplet"]["id"]' 2>/dev/null )

rm $TMP

echo
[ "$WAIT" == 1 ] && [ -n "$ACTION_ID" ] && { 
        do_wait_for_action $DROPLET_ID $ACTION_ID
        do_get_ip $DROPLET_ID 
        }


}
###########################

do_get_ip () {

local DROPLET_ID=$( do_get_id $1)
echo $DROPLET_ID | grep -P '^\d+$' -q || { echo "use number only in do_get_ip arguement" ; exit 2; }

local TMP=$(mktemp)
curl -Ss -X GET -H "Content-Type: application/json" -H "Authorization: Bearer $DO_TOKEN" "https://api.digitalocean.com/v2/droplets/$DROPLET_ID" > $TMP

local IP=$( cat $TMP|json_xs | grep ip_address | grep  -oP '\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}')
echo $IP

rm $TMP


}

###########################

do_rename () {

local DROPLET_ID=$( do_get_id $1)
local NAME=$(  echo ${BASH_ARGV[*]}  | grep -P "\bname=\S+\b" -o | cut -d= -f2  )
local TMP=$(mktemp)

curl -Ss -X POST "https://api.digitalocean.com/v2/droplets/$DROPLET_ID/actions" -d '{"type":"rename","name":"'$NAME'"}' -H "Authorization: Bearer $DO_TOKEN"   -H "Content-Type: application/json" | tee $TMP
echo
local ACTION_ID=$( cat $TMP| python -c 'import json,sys;obj=json.load(sys.stdin);print obj["action"]["id"]' 2>/dev/null )
#echo ACTION_ID=$ACTION_ID
rm $TMP
[ "$WAIT" == 1 ] && [ -n "$ACTION_ID" ] && do_wait_for_action $DROPLET_ID $ACTION_ID

}
##############################
do_wait_for_action () {

local DROPLET_ID=$( do_get_id $1)
local ACTION_ID=$2

while   :
do
        local STATUS=$( do_get_action_status $DROPLET_ID $ACTION_ID | \
                python -c 'import json,sys;obj=json.load(sys.stdin);print obj["action"]["status"]' )
        echo "STATUS=$STATUS"
        [ "$STATUS" == completed ] && break
        sleep 5
done

}

#############################

usage () {

echo " 
do_change_kernel        {HOSTNAME|DROPLET_ID} KERNEL_ID  [wait=1]
do_get_action_status    {HOSTNAME|DROPLET_ID} ACTION_ID
do_get_id               HOSTNAME                        // returns DO ID by droplet name
do_list_available_kernels
do_list_droplets
do_power_cycle          {HOSTNAME|DROPLET_ID} [wait=1]
do_power_off            {HOSTNAME|DROPLET_ID} [wait=1]
do_power_on             {HOSTNAME|DROPLET_ID} [wait=1]
do_wait_for_action      {HOSTNAME|DROPLET_ID} ACTION_ID
do_create_droplet       region=nyc1 name=cacheq111.rmkr.net size=512mb image=ubuntu-14-04-x64 [wait=1]
        size: one of 512mb,1gb,2gb,4gb,8gb,16gb,m-16gb,32gb,m-32gb,48gb,m-64gb,64gb
        region: one of ams1,ams2,ams3,blr1,fra1,lon1,nyc1,nyc2,nyc3,sfo1,sfo2,sgp1,tor1
do_get_ip               {HOSTNAME|DROPLET_ID}
do_destroy              {HOSTNAME|DROPLET_ID}
do_rename               {HOSTNAME|DROPLET_ID} name=newname.com 
"

}

################################

ACTION=$1
shift

case $ACTION in
do_change_kernel|do_list_available_kernels|do_list_droplets|do_get_action_status|do_get_id|do_power_cycle|do_power_on|do_power_off|do_wait_for_action|do_create_droplet|do_get_ip|do_destroy|do_rename)
        $ACTION $@
        ;;
*)      #echo wrong option
        usage
        ;;
esac
