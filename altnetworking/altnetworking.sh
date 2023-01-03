#!/bin/bash

# === INFO ===
# altnetworking.sh
# Description: Run the specified application in a custom networking environment.
# Uses cgroups to run process(es) in a network environment of your own choosing (within limits!)
VERSION="0.1.0"
# Author: John Clark
# Requirements:  Debian 8 Jessie (plus iptables 1.6 from unstable)
#
# This script was derived from the excellent "novpn.sh" script by KrisWebDev
#   as found here: https://gist.github.com/kriswebdev/a8d291936fe4299fb17d3744497b1170
#
# === LICENSE ===
#    This program is free software: you can redistribute it and/or modify
#    it under the terms of the GNU General Public License as published by
#    the Free Software Foundation, either version 3 of the License, or
#    (at your option) any later version.
#
#    This program is distributed in the hope that it will be useful,
#    but WITHOUT ANY WARRANTY; without even the implied warranty of
#    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#    GNU General Public License for more details.
#
#    You should have received a copy of the GNU General Public License
#    along with this program.  If not, see <http://www.gnu.org/licenses/>.

# This script will `source` a configuration script identified by the first command line argument.
# That configuration script is expected to define:
#
# 1. The name of the interface that we want the command to emit packets from
#       e.g. desired_interface="eth0"
# 2. The default route we want to have for our cgroup
#       e.g. desired_default_route=`ip route | grep "dev ${desired_interface}" | awk '/^default/ { print $3 }'`
# 3. The name for the cgroup we're going to create
#       Note: Better keep it with purely lowercase alphabetic & underscore
#       e.g. cgroup_name="vpntinclpgmtwireless" 
# 4. The classid we're going to use for this cgroup
#       Note: Anything from 0x00000001 to 0xFFFFFFFF (just needs to be unique)
#       e.g. net_cls_classid="0x00110011" 
# 5. The mark we're going to put on packets originating from this app/cgroup
#       Note: Anything from 1 to 2147483647
#       e.g. ip_table_fwmark="11"
# 6. The Routing table number we'll associate with packets on this cgroup
#       Note: Anything from 1 to 252 (just needs to be unique)
#       e.g. ip_table_number="11" 
# 7. The routing table name we're going to use to formulate the full routing table name
#       Note: Needs to be unique. Best to use cgroup name
#       e.g. ip_table_name="$cgroup_name"
# 8. Define a post_up() function that will be called after everything about 
#       the cgroup is set up (including default route)
#       Use it to create additional needed routes and/or iptables entries
#       e,g post_up(){
#               echo "Adding routes to LPGMT lan via vpn-tinc-telstra-wireless-01-node-11"
#               ip route add 10.0.1.0/24 via 10.11.12.9 dev "$desired_interface" table "$ip_table_name"
#               ip route add 10.0.99.0/24 via 10.11.12.9 dev "$desired_interface" table "$ip_table_name"
#           }
# 9. Define a pre_down() function that will be called before everything about the cgroup is is torn down
#       Use it to undo everything in post_up
#       e.g. pre_down(){
#               echo "Removing routes to LPGMT lan"
#               ip route del 10.0.1.0/24 via 10.11.12.9 dev "$desired_interface" table "$ip_table_name"
#               ip route del 10.0.99.0/24 via 10.11.12.9 dev "$desired_interface" table "$ip_table_name"
#            }
#
# 10 Define the test_networking() function that will carry out tests to confirm that the
#       networking environment that has been created is functioning properly. It should return 0 if 
#       networking is functioning correctly or 1 otherwise. If returning 0, set testresult=true else
#       set it to false
#       e.g. test_networking(){
#                   echo "Networking was not tested by the test_networking function. Confirm it's working manually if you feel the need"
#                   testresult=true
#                   return 0
#             }


# === CODE ===

set -u 

# Some defaults
force=false
testresult=true

# Handle options
action="command"
background=false
skip=false
init_nb_args="$#"


show_help() {
        me=`basename "$0"`
        echo -e "Usage : \e[1m$me \e[4mCONFIG\e[24m [\e[4mOPTIONS\e[24m] [\e[4mCOMMAND\e[24m [\e[4mCOMMAND PARAMETERS\e[24m]]\e[0m"
        echo -e "Run command using different networking configuration (via cgroups)."
        echo
        echo -e "\e[1m\e[4mCONFIG\e[0m:             Full path to the configuration file"
        echo -e "\e[1m\e[4mOPTIONS\e[0m:"
        echo -e "\e[1m-b, --background\e[0m    Start \e[4mCOMMAND\e[24m as background process (release the shell)."
        echo -e "\e[1m-l, --list\e[0m          List processes running in this special cgroup namespace."
        echo -e "\e[1m-s, --skip\e[0m          Don't check/setup system config & don't ask for root,\n\
                     run \e[4mCOMMAND\e[24m even if network connectivity tests fail."
        echo -e "\e[1m-c, --clean\e[0m         Terminate all proceses inside cgroup and remove system config."
        echo -e "\e[1m-v, --version\e[0m       Print this program version."
        echo -e "\e[1m-h, --help\e[0m          This help."
}

config_file_name="$1"
if [ -f "$config_file_name" ]
then
    source "$config_file_name"
else
    show_help
    exit 1
fi

shift

while [ "$#" -gt 0 ]; do
  case "$1" in
    -b|--background) background=true; shift 1;;
    -l|--list) action="list"; shift 1;;
    -s|--skip) skip=true; shift 1;;
    -l|--clean) action="clean"; shift 1;;
    -h|--help) action="help"; shift 1;;
    -v|--version) echo "altnetworking.sh v$VERSION"; exit 0;;
    -*) echo "Unknown option: $1. Try --help." >&2; exit 1;;
    *) break;; # Start of COMMAND or LIST
  esac
done

# Respond to --help
if [ "$init_nb_args" -lt 1 ] || [ "$action" = "help" ] ; then
	show_help
	exit 1
fi


# Helper functions

# Check the presence of required system packages
check_package(){
	nothing_installed=1
	for package_name in "$@"
	do
		if ! dpkg -l "$package_name" &> /dev/null; then
			echo "Installing $package_name"
			apt-get install "$package_name"
			nothing_installed=0
		fi
	done
	return $nothing_installed
}

# List processes running inside the cgroup
list_processes(){
	return_status=1
	echo -e "PID""\t""CMD"
	while read task_pid
		do
			echo -e "${task_pid}""\t""`ps -p ${task_pid} -o comm=`";
			return_status=0
	done < /sys/fs/cgroup/net_cls/${cgroup_name}/tasks
	return $return_status
}

# Check and setup iptables - requires root even for check
iptable_checked=false
setup_iptables(){
	if ! iptables -t mangle -C OUTPUT -m cgroup --cgroup "$net_cls_classid" -j MARK --set-mark "$ip_table_fwmark" 2>/dev/null; then
		echo "Adding iptables MANGLE rule to set firewall mark $ip_table_fwmark on packets with class identifier $net_cls_classid" >&2
		iptables -t mangle -A OUTPUT -m cgroup --cgroup "$net_cls_classid" -j MARK --set-mark "$ip_table_fwmark"
	fi
	if ! iptables -t nat -C POSTROUTING -m cgroup --cgroup "$net_cls_classid" -o "$desired_interface" -j MASQUERADE 2>/dev/null; then
		echo "Adding iptables NAT rule force the packets with class identifier $net_cls_classid to exit through $desired_interface" >&2
		iptables -t nat -A POSTROUTING -m cgroup --cgroup "$net_cls_classid" -o "$desired_interface" -j MASQUERADE
	fi

	iptable_checked=true
}

# Test if config is working, IPv4 only
test_connection(){
    # Call the configuration function to test if networking is functioning
    test_networking
}


check_iptables=false
if [ "$action" = "command" ]
then
	# SETUP config
	if [ "$skip" = false ]; then
		echo "Checking/setting forced routing config (skip with $0 -s ...)" >&2

		if check_package cgroupfs-mount  cgroup-tools inetutils-traceroute; then
			echo "You may want to reboot now. But that's probably not necessary." >&2
			exit 1
		fi

		if dpkg --compare-versions `iptables --version | grep -oP "iptables v\K.*$" | cut -d\   -f1 ` "lt" "1.6"; then
			echo -e "\e[31mYou need iptables 1.6.0+. Please install manually. Aborting.\e[0m" >&2
			echo "Find latest iptables at https://www.netfilter.org/projects/iptables/downloads.html" >&2
			echo "Commands to install iptables 1.6.0:" >&2
                        echo "apt-get install iptables/unstable libxtables11/unstable" >&2
                        echo "... or compile from source as shown below:" >&2
			echo -e "\e[34mapt-get install dh-autoreconf bison flex
cd /tmp
curl https://www.netfilter.org/projects/iptables/files/iptables-1.6.0.tar.bz2 | tar xj
cd iptables-1.6.0
./configure --prefix=/usr      \\
            --sbindir=/sbin    \\
            --disable-nftables \\
            --enable-libipq    \\
            --with-xtlibdir=/lib/xtables \\
&& make  \\
&& make install
iptables --version\e[0m" >&2
			exit 1
		fi		

		if [ ! -d "/sys/fs/cgroup/net_cls/$cgroup_name" ]; then
			echo "Creating net_cls control group $cgroup_name" >&2
			mkdir -p "/sys/fs/cgroup/net_cls/$cgroup_name"
			check_iptables=true
		fi
		if [ `cat "/sys/fs/cgroup/net_cls/$cgroup_name/net_cls.classid" | xargs -n 1 printf "0x%08x"` != "$net_cls_classid" ]; then
			echo "Applying net_cls class identifier $net_cls_classid to cgroup $cgroup_name" >&2
			echo "$net_cls_classid" | tee "/sys/fs/cgroup/net_cls/$cgroup_name/net_cls.classid" > /dev/null
		fi
		if ! grep -E "^${ip_table_number}\s+$ip_table_name" /etc/iproute2/rt_tables &>/dev/null; then
			if grep -E "^${ip_table_number}\s+" /etc/iproute2/rt_tables; then
				echo "ERROR: Table ${ip_table_number} already exists in /etc/iproute2/rt_tables with a different name than $ip_table_name" >&2
				exit 1
			fi
			echo "Creating ip routing table: number=$ip_table_number name=$ip_table_name" >&2
			echo "$ip_table_number $ip_table_name" | tee -a /etc/iproute2/rt_tables > /dev/null
			check_iptables=true
		fi
        # ubuntu <=18.04 has ending spaces in `ip rule list` output.
		if ! ip rule list | grep -E " lookup $ip_table_name( )?$" | grep " fwmark " &>/dev/null; then
			echo "Adding rule to use ip routing table $ip_table_name for packets with firewall mark $ip_table_fwmark" >&2
			ip rule add fwmark "$ip_table_fwmark" table "$ip_table_name"
			check_iptables=true
		fi
		if [ -z "`ip route list table "$ip_table_name" default via $desired_default_route dev ${desired_interface} 2>/dev/null`" ]; then
			echo "Adding default route in ip routing table $ip_table_name via $desired_default_route dev $desired_interface" >&2
			ip route rep default via "$desired_default_route" dev "$desired_interface" table "$ip_table_name"
			# Now run custom post_up script
			post_up
			# Useless?
			echo "Flushing ip route cache" >&2
			ip route flush cache
			check_iptables=true
		fi
		if [ "`cat /proc/sys/net/ipv4/conf/all/rp_filter`" != "0" ] || [ "`cat /proc/sys/net/ipv4/conf/all/rp_filter`" != "2" ]; then
			echo "Unset reverse path filtering for interface \"all\"" >&2
			echo 2 | tee "/proc/sys/net/ipv4/conf/all/rp_filter" > /dev/null
			check_iptables=true
		fi
		if [ "`cat /proc/sys/net/ipv4/conf/${desired_interface}/rp_filter`" != "0" ] || [ "`cat /proc/sys/net/ipv4/conf/${desired_interface}/rp_filter`" != "2" ]; then
			echo "Unset reverse path filtering for interface \"${desired_interface}\"" >&2
			echo 2 | tee "/proc/sys/net/ipv4/conf/${desired_interface}/rp_filter" > /dev/null
			check_iptables=true
		fi
        USER_local=${USER:-root}

		if [ -z "`lscgroup net_cls:$cgroup_name`" ] || [ `stat -c "%U" /sys/fs/cgroup/net_cls/${cgroup_name}/tasks` != "$USER_local" ]; then
			echo "Creating cgroup net_cls:${cgroup_name}. User $USER_local will be able to move tasks to it without root permissions." >&2
			cgcreate -t "$USER_local":"$USER_local" -a `id -g -n "$USER_local"`:`id -g -n "$USER_local"` -g net_cls:"$cgroup_name"
			check_iptables=true
		fi
		if [ "$check_iptables" = true ]; then
			setup_iptables
		fi

	fi

	# TEST bypass
	test_connection
	if [ "$force" != true ]; then
		if [ "$testresult" = false ]; then
			if [ "$iptable_checked" = false ]; then
				echo -e "Testing iptables..." >&2
				setup_iptables
				test_connection
			fi
		fi
		if [ "$testresult" = false ]; then
			exit 1
		fi
	fi
fi

# RUN command
if [ "$action" = "command" ]; then
	if [ "$#" -eq 0 ]; then
		echo "Error: COMMAND not provided." >&2
		exit 1
	fi
	if [ "$background" = true ]; then
		cgexec -g net_cls:"$cgroup_name" "$@" &>/dev/null &
		exit 0
	else
		cgexec -g net_cls:"$cgroup_name" "$@"
		exit $?
	fi

# List processes using this cgroup
# Exit code 0 (true) if at least 1 process is running in the cgroup
elif [ "$action" = "list" ]; then
	echo "List of processes using cgroup $cgroup_name:"
	list_processes
	exit $?



# CLEAN the mess
elif [ "$action" = "clean" ]; then
	echo -e "Cleaning forced routing config generated by this script."
	echo -e "Don't bother with errors meaning there's nothing to remove."

	# Kill tasks in cgroup
	if [ -f "/sys/fs/cgroup/net_cls/${cgroup_name}/tasks" ]; then
		while read task_pid; do kill ${task_pid} ; done < "/sys/fs/cgroup/net_cls/${cgroup_name}/tasks"
	fi

	# Run custom pre_down function
	pre_down
	
	# Delete cgroup
	if [ -d "/sys/fs/cgroup/net_cls/${cgroup_name}" ]; then
		find "/sys/fs/cgroup/net_cls/${cgroup_name}" -depth -type d -print -exec rmdir {} \;
	fi

	# (DISABLED BECAUSE MY MACHINE DEFAULTS TO RPF BEING OFF) Re-enable Reverse Path Filtering
	#echo 1 | tee "/proc/sys/net/ipv4/conf/all/rp_filter" > /dev/null
	#echo 1 | tee "/proc/sys/net/ipv4/conf/${desired_interface}/rp_filter" > /dev/null

	iptables -t mangle -D OUTPUT -m cgroup --cgroup "$net_cls_classid" -j MARK --set-mark "$ip_table_fwmark"
	iptables -t nat -D POSTROUTING -m cgroup --cgroup "$net_cls_classid" -o "$desired_interface" -j MASQUERADE
    iptables -D OUTPUT -m cgroup --cgroup "$net_cls_classid" ! -o "$desired_interface" -j REJECT 

	ip rule del fwmark "$ip_table_fwmark" table "$ip_table_name"	
	ip route del default table "$ip_table_name"
        
	sed -i '/^${ip_table_number}\s\+${ip_table_name}\s*$/d' /etc/iproute2/rt_tables

	if [ -n "`lscgroup net_cls:$cgroup_name`" ]; then
		cgdelete net_cls:"$cgroup_name"
	fi

	echo "All done."

fi

# BONUS: Useful commands:
# ./altnetworking.sh traceroute www.google.com
# ip=$(./altnetworking.sh curl 'https://wtfismyip.com/text' 2>/dev/null); echo "$ip"; whois "$ip" | grep -E "inetnum|route|netname|descr"
