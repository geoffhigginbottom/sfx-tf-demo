#! /bin/bash
# Version 2.0

UNIVERSAL_FORWARDER_FILENAME=$1
UNIVERSAL_FORWARDER_URL=$2
PASSWORD=$3
SPLUNK_IP=$4

wget -O $UNIVERSAL_FORWARDER_FILENAME $UNIVERSAL_FORWARDER_URL
sudo dpkg -i $UNIVERSAL_FORWARDER_FILENAME
sudo /opt/splunkforwarder/bin/splunk cmd splunkd rest --noauth POST /services/authentication/users "name=admin&password=$PASSWORD&roles=admin"
sudo /opt/splunkforwarder/bin/splunk start --accept-license
sudo /opt/splunkforwarder/bin/splunk stop
sudo /opt/splunkforwarder/bin/splunk enable boot-start
sudo /opt/splunkforwarder/bin/splunk start
sudo /opt/splunkforwarder/bin/splunk add forward-server $SPLUNK_IP:9997 -auth admin:$PASSWORD    # adds to /opt/splunkforwarder/etc/system/local/outputs.conf
sudo /opt/splunkforwarder/bin/splunk add monitor /var/log/syslog -auth admin:$PASSWORD           # adds to /opt/splunkforwarder/etc/apps/search/local/inputs.conf
sudo /opt/splunkforwarder/bin/splunk add monitor /var/log/apache2 -auth admin:$PASSWORD          # adds to /opt/splunkforwarder/etc/apps/search/local/inputs.conf
