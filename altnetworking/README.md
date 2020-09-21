

prereqs:

    apt install cgroupfs-mount  cgroup-tools inetutils-traceroute

Assign IP to an interface; Edit namespace.1 from namespace.template

Run

./altnetworking.sh ./namespace.1 bash

Done, all subseq commands will be executed in new namespace with custom routing.

