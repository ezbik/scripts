
### Custom routing table for set of  processes.



Based on https://gist.github.com/level323/54a921216f0baaa163127d960bfebbf0

Prereqs:

    apt install cgroupfs-mount  cgroup-tools inetutils-traceroute

Assign IP to an interface `eth222`; 
Copy `namespace.template` to `namespace.1`
Edit `namespace.1`, change `__N__` to 1 ;  `__IFACE__` to `eth222` ; `__GW__` to custom gateway;


Run

    ./altnetworking.sh ./namespace.1 curl ifconfig.co
    ./altnetworking.sh ./namespace.1 bash

Done, all subseq commands will be executed in new namespace with custom routing.

