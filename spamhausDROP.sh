#!/bin/bash
timestamp=$(date +'%d-%m-%Y_%H-%M-%S') 	# Day-Month-Year_Hour-Minutes-Seconds (12-06-2019_05-05-38)
URL="http://www.spamhaus.org/drop/drop.lasso"
drop=/tmp/drop.lasso.$$.$RANDOM 	# tmp file /tmp/<drop>.<lasso>.<CurrentUserPid>.<random number>
log=/tmp/drop.lasso.$$.$timestamp.log # log file /tmp/<drop>.<lasso>.<CurrentUserPid>.<timestamp>.<log>
iptChain="DROPlist" 	# iptables chain name
trap "rm -f $drop, $log" EXIT 	# exit trap to clean tmp file
function importDROP {
for ipblock in $blocks
	do
	 iptables -A $iptChain -s $ipblock -j LOG --log-prefix "[Spamhaus DROP List]"	# log all traffic on chain iptChain
	 iptables -A $iptChain -s $ipblock -j DROP 	# drop traffic
done
iptables -I INPUT -j $iptChain	# add iptChain to INPUT chain
iptables -I OUTPUT -j $iptChain	# add iptChain to OUTPUT chain
iptables -I FORWARD -j $iptChain	# add iptChain to FOWARD chain
	}

echo -n "Attempting to Apply the newest spamhaus DROP list to the existing firewall rules..."
wget -q -O $drop $URL 	# Download list
blocks=$(cat $drop | egrep -v '^;' | while read line ; do echo ${line%%;*} ; done)	# Cleanup the list
iptables -N $iptChain 
if [ $? ]; >> "$log"; then
        echo "Flushing existing chain [$iptChain]..."
        iptables -F $iptChain
        importDROP
        echo "Done."
 else [];
        echo "Creating new chain [$iptChain]..."
        iptables -N $iptChain
        importDROP
        echo "Done."
fi
