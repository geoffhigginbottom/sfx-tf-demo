#! /bin/bash
# Version 2.0

PASSWORD=$1
VERSION=$2
FILENAME=$3
LO_CONNECT_PASSWORD=$4

# wget -O /tmp/$FILENAME "https://www.splunk.com/bin/splunk/DownloadActivityServlet?architecture=x86_64&platform=linux&version=$VERSION&product=splunk&filename=$FILENAME&wget=true"
wget -O /tmp/$FILENAME "https://download.splunk.com/products/splunk/releases/$VERSION/linux/$FILENAME"
dpkg -i /tmp/$FILENAME
/opt/splunk/bin/splunk cmd splunkd rest --noauth POST /services/authentication/users "name=admin&password=$PASSWORD&roles=admin"
/opt/splunk/bin/splunk start --accept-license --answer-yes --no-prompt --seed-passwd $PASSWORD
/opt/splunk/bin/splunk enable boot-start

#Enable Token Auth
curl -k -u admin:$PASSWORD -X POST https://localhost:8089/services/admin/token-auth/tokens_auth -d disabled=false

#Enable Receiver
/opt/splunk/bin/splunk enable listen 9997 -auth admin:$PASSWORD

#Add LOC Role
curl -k -u admin:$PASSWORD https://localhost:8089/services/admin/roles \
  -d name=lo_connect\
  -d srchIndexesAllowed=%2A \
  -d imported_roles=user \
  -d srchJobsQuota=12 \
  -d rtSrchJobsQuota=0 \
  -d cumulativeSrchJobsQuota=12 \
  -d cumulativeRTSrchJobsQuota=0 \
  -d srchTimeWin=2592000 \
  -d srchTimeEarliest=7776000 \
  -d srchDiskQuota=1000 \
  -d capabilities=edit_tokens_own

#Add LOC User
/opt/splunk/bin/splunk add user LO-Connect -role lo_connect -password $LO_CONNECT_PASSWORD -auth admin:$PASSWORD

#Add K8S-Logs Index
/opt/splunk/bin/splunk add index k8s-logs -auth admin:$PASSWORD

#Enable HEC
/opt/splunk/bin/splunk http-event-collector enable -uri https://localhost:8089 -enable-ssl 0 -port 8088 -auth admin:$PASSWORD

#Create HEC Tokens
/opt/splunk/bin/splunk http-event-collector create OTEL-K8S -uri https://localhost:8089 -description "Used by OTEL K8S" -disabled 0 -index k8s-logs -indexes k8s-logs -auth admin:$PASSWORD
/opt/splunk/bin/splunk http-event-collector create OTEL -uri https://localhost:8089 -description "Used by OTEL" -disabled 0 -index main -indexes main -auth admin:$PASSWORD