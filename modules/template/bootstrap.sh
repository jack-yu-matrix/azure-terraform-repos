#!/bin/bash
yum -y update
exec > >(tee /root/user-data.log|logger -t user-data -s 2>/dev/console) 2>&1
set -vx

iptables -F
service iptables save
service iptables stop
chkconfig iptables off

