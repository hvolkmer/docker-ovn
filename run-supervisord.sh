#!/bin/sh

if [ -z "$IPAM_IP" ]; then
    echo "IPAM_IP is empty. Use -e IPAM_IP=<IP>"
    exit 1
fi
if [ -z "$LOCAL_IP" ]; then
    echo "LOCAL_IP is empty. Use -e LOCAL_IP=<IP>"
    exit 1
fi

echo $IPAM_IP > /etc/ovn-ipam-ip
echo $LOCAL_IP > /etc/ovn-local-ip

/usr/bin/supervisord