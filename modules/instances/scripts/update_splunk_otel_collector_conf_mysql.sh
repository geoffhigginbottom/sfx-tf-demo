#! /bin/bash
# Version 2.0
## Configure the otel agent to use the Gateway via the internal address of the LB

LBURL=$1
MYSQL_USER=$2
MYSQL_USER_PWD=$3

if [ -z "$1" ] ; then
  printf "LB URL not set, exiting ...\n"
  exit 1
else
  printf "LB URL Variable Detected...\n"
fi

cp /etc/otel/collector/splunk-otel-collector.conf /etc/otel/collector/splunk-otel-collector.bak

echo SPLUNK_GATEWAY_URL=$LBURL >> /etc/otel/collector/splunk-otel-collector.conf
echo MYSQL_USER=$MYSQL_USER >> /etc/otel/collector/splunk-otel-collector.conf
echo MYSQL_USER_PWD=$MYSQL_USER_PWD >> /etc/otel/collector/splunk-otel-collector.conf

systemctl restart splunk-otel-collector