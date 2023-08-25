#! /bin/bash
# Version 2.0

ENV=$1

cat << EOF > /home/ubuntu/values.yaml
monitors:
- type: signalfx-forwarder
  listenAddress: 0.0.0.0:9080
  extraSpanTags:
    environment: $ENV-eks-demo

- type: kubernetes-events
  whitelistedEvents:
   - reason: Killing
     involvedObjectKind: Pod
   - reason: Created
     involvedObjectKind: Pod
   - reason: ScalingReplicaSet
     involvedObjectKind: Deployment
   - reason: SuccessfulCreate
     involvedObjectKind: ReplicaSet
   - reason: Scheduled
     involvedObjectKind: Pod
   - reason: Started
     involvedObjectKind: Pod
   - reason: Pulled
     involvedObjectKind: Pod
EOF
