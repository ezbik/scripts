#!/usr/bin/env python3

# designed to accept `watson log` on stdin and make it more cool & detailed.

import sys, json;
import requests

from datetime import datetime, timedelta

from dateutil.parser import parse

data = json.load(sys.stdin)


total_time_spent=timedelta()

for item in data:
    #print (item,"\n")

    project = item['project']
    date1 = parse(item['start'])
    date2 = parse(item['stop'])
    time_spent=date2 - date1
    total_time_spent+=time_spent
    id=item['id'][0:8]
    line=date1.strftime("%F") + ", from "   \
        + date1.strftime("%H:%M") + " to " + date2.strftime("%H:%M") + \
        ", spent " + str(time_spent)+" for customer : " + project + ", on [" + id + "] " +  ",".join(item['tags'] ) 
    print (line)

print ("TOTAL "+str(total_time_spent))

