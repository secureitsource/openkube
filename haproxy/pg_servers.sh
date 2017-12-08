#!/bin/bash -e
#
# Usage: ./pg_servers.sh
#
# Generates a list of conjur-master PG servers in HAProxy format into pg_servers.cfg.
# Pod names & IP addresses are obtained via kubectl.

destination_file="pg_servers.cfg"

cat <<CONFIG > $destination_file
# This file is generated by pg_servers.sh

backend b_conjur_master_pg
	mode tcp
	balance static-rr
	option external-check
	default-server inter 5s fall 3 rise 2
	external-check path "/usr/bin:/usr/local/bin"
	external-check command "/root/conjur-health-check.sh"
CONFIG

pod_list=$(kubectl get pods -l app=conjur-appliance --no-headers \
						| awk '{print $1}')
for pod_name in $pod_list; do
	pod_ip=$(kubectl describe pod $pod_name | awk '/IP:/ {print $2}')
	echo -e '\t' server $pod_name $pod_ip:5432 check >> $destination_file
done

exit 0
