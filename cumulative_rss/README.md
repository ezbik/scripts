cumulative rss
==============

The script is to 
* merge various RSS feeds into single one. Useful when you're a freelancer and need to get instant updates from both Odesk.com & Freelancer.com
* Score assigning. Good keywords increase it, bad keywords decrease. So you can pick up the job where you are pro at. 
* good & bad keyword highliting with different colors
* get only rss pages from 3 last days 

prereqs:

    apt-get install  libdatetime-format-w3cdtf-perl libxml-feedpp-perl 

Installation:

crontab:

    */5 * * * *     timeout 90 run-one /usr/local/bin/cumulative_rss.threads > /dev/null
    */5 * * * *     timeout 90 run-one /usr/local/bin/cumulative_rss.threads -f /etc/rss.gaf -o /var/www/gaf.rss > /dev/null


