#!/bin/bash
export CLUSTERNAME=$1
export DOMAINNAME=$2
export OPENSHIFTUSER=$3
export OPENSHIFTPASSWORD=$4

NAMESPACE="openshift-storage"
maxWaitTime=900


#Print a formatted time in minutes and seconds from the given input in seconds
function output_time {
  SECONDS=${1}
  if((SECONDS>59));then
    printf "%d minutes, %d seconds" $((SECONDS/60)) $((SECONDS%60))
  else
    printf "%d seconds" "$SECONDS"
  fi
}

#Function to check for subscription
function wait_for_subscription {
  NAMESPACE=${1}
  NAME=${2}

  phase=""
  # inital time
  time=0
  # wait interval - how often the status is checked in seconds
  wait_time=5

  until [[ "$phase" == "Succeeded" ]]; do
    csv=$(oc get subscription -n "${NAMESPACE}" "${NAME}" -o json | jq -r .status.currentCSV)
    wait=0
    if [[ "$csv" == "null" ]]; then
      echo "INFO: Waited for $(output_time $time), not got csv for subscription"
      wait=1
    else
      phase=$(oc get csv -n "${NAMESPACE}" "$csv" -o json | jq -r .status.phase)
      if [[ "$phase" != "Succeeded" ]]; then
        echo "INFO: Waited for $(output_time $time), csv not in Succeeded phase, currently: $phase"
        wait=1
      fi
    fi

    # if subscriptions hasn't succeeded yet: wait
    if [[ "$wait" == "1" ]]; then
      ((time=time+$wait_time))
      if [ "$time" -gt $maxWaitTime ]; then
        echo "ERROR: Failed after waiting for $((maxWaitTime/60)) minutes"
        # delete subscription after maxWaitTime has exceeded        
        return 1
      fi

      # wait
      sleep $wait_time
    fi
  done
  echo "INFO: $NAME has succeeded"
}


function create_storage_cluster {
  echo "Creating Default Storage Cluster with 2Ti space"
  
  cat <<EOF | oc apply -f -
--- 
apiVersion: ocs.openshift.io/v1
kind: StorageCluster
metadata:
  name: ocs-storagecluster
  namespace: openshift-storage
spec:
  arbiter: {}
  encryption:
    kms: {}
  externalStorage: {}
  managedResources:
    cephBlockPools: {}
    cephConfig: {}
    cephDashboard: {}
    cephFilesystems: {}
    cephObjectStoreUsers: {}
    cephObjectStores: {}
  nodeTopologies: {}
  storageDeviceSets:
    - config: {}
      resources: {}
      placement: {}
      name: ocs-deviceset-managed-premium
      dataPVCTemplate:
        metadata: {}
        spec:
          accessModes:
            - ReadWriteOnce
          resources:
            requests:
              storage: 2Ti
          storageClassName: managed-premium
          volumeMode: Block
        status: {}
      count: 1
      replica: 3
      portable: true
      preparePlacement: {}
  version: 4.8.0
EOF
}


#Function to validate openshift container storage instances . Below components will be validated:
#StorageCluster
#CephBlockPool
#BucketClass
#BackingStore

function validate_components {
COMPONENT=${1}

#Validating status of storage cluster
time=0
status=false;
while [[ "$status" == false ]]; do
	
	currentStatus="$(oc get "${COMPONENT}" -n openshift-storage -o json | jq -r .items[].status.phase)";
	if [ "$currentStatus" == "Ready" ] || [ "$currentStatus" == "Running" ]
  then
     status=true
  fi
	
	echo "${COMPONENT} status: $currentStatus"
    
    if [ $time -gt $maxWaitTime ]; then
      echo "ERROR: Exiting installation of ${COMPONENT}"
      return 1
    fi

    echo "INFO: Waiting for ${COMPONENT} to be ready. Waited ${time} second(s)."

    time=$((time + 60))
    sleep 60
done

}

echo "INFO: Starting Openshift Container Storage Configuration "

#TODO: Not needed for now ... Login to openshift cluster

#echo "Attempting to login $OPENSHIFTUSER to https://api.${CLUSTERNAME}.${DOMAINNAME}:6443 "
#  oc login "https://api.${CLUSTERNAME}.${DOMAINNAME}:6443" -u $OPENSHIFTUSER -p $OPENSHIFTPASSWORD --insecure-skip-tls-verify=true
#  var=$?
#  echo "exit code: $var"

#Get worker nodes for labelling
echo "INFO: Labelling Worker Nodes with openshift-storage label"

WORKERNODES=$(oc get nodes | grep worker)

while IFS= read -r line ; do
        IFS='  ' #setting space as delimiter
        read -ra node <<<"$line" #reading str as an array as tokens separated by IFS
		echo "Labeling Node : ${node[0]}"
        oc label nodes "${node[0]}" cluster.ocs.openshift.io/openshift-storage=''

done <<< "$WORKERNODES"

#Installing OCS operator can be installed into an OpenShift cluster using Operator Lifecycle Manager (OLM).
#Source: https://raw.githubusercontent.com/openshift/ocs-operator/master/deploy/deploy-with-olm.yaml
#This creates:
#Custom CatalogSource
#New openshift-storage Namespace
#OperatorGroup
#Subscription to the OCS catalog in the openshift-storage namespace
echo "INFO: Installing OpenShift Container Storage Operator"

cat <<EOF | oc apply -f -
---
apiVersion: v1
kind: Namespace
metadata:
  labels:
    openshift.io/cluster-monitoring: "true"
  name: ${NAMESPACE}
spec: {}
---
apiVersion: operators.coreos.com/v1
kind: OperatorGroup
metadata:
  name: openshift-storage-operatorgroup
  namespace: openshift-storage
spec:
  targetNamespaces:
  - openshift-storage
---
apiVersion: operators.coreos.com/v1alpha1
kind: CatalogSource
metadata:
  name: ocs-catalogsource
  namespace: openshift-marketplace
spec:
  displayName: OpenShift Container Storage
  icon:
    base64data: PHN2ZyBpZD0iTGF5ZXJfMSIgZGF0YS1uYW1lPSJMYXllciAxIiB4bWxucz0iaHR0cDovL3d3dy53My5vcmcvMjAwMC9zdmciIHZpZXdCb3g9IjAgMCAxOTIgMTQ1Ij48ZGVmcz48c3R5bGU+LmNscy0xe2ZpbGw6I2UwMDt9PC9zdHlsZT48L2RlZnM+PHRpdGxlPlJlZEhhdC1Mb2dvLUhhdC1Db2xvcjwvdGl0bGU+PHBhdGggZD0iTTE1Ny43Nyw2Mi42MWExNCwxNCwwLDAsMSwuMzEsMy40MmMwLDE0Ljg4LTE4LjEsMTcuNDYtMzAuNjEsMTcuNDZDNzguODMsODMuNDksNDIuNTMsNTMuMjYsNDIuNTMsNDRhNi40Myw2LjQzLDAsMCwxLC4yMi0xLjk0bC0zLjY2LDkuMDZhMTguNDUsMTguNDUsMCwwLDAtMS41MSw3LjMzYzAsMTguMTEsNDEsNDUuNDgsODcuNzQsNDUuNDgsMjAuNjksMCwzNi40My03Ljc2LDM2LjQzLTIxLjc3LDAtMS4wOCwwLTEuOTQtMS43My0xMC4xM1oiLz48cGF0aCBjbGFzcz0iY2xzLTEiIGQ9Ik0xMjcuNDcsODMuNDljMTIuNTEsMCwzMC42MS0yLjU4LDMwLjYxLTE3LjQ2YTE0LDE0LDAsMCwwLS4zMS0zLjQybC03LjQ1LTMyLjM2Yy0xLjcyLTcuMTItMy4yMy0xMC4zNS0xNS43My0xNi42QzEyNC44OSw4LjY5LDEwMy43Ni41LDk3LjUxLjUsOTEuNjkuNSw5MCw4LDgzLjA2LDhjLTYuNjgsMC0xMS42NC01LjYtMTcuODktNS42LTYsMC05LjkxLDQuMDktMTIuOTMsMTIuNSwwLDAtOC40MSwyMy43Mi05LjQ5LDI3LjE2QTYuNDMsNi40MywwLDAsMCw0Mi41Myw0NGMwLDkuMjIsMzYuMywzOS40NSw4NC45NCwzOS40NU0xNjAsNzIuMDdjMS43Myw4LjE5LDEuNzMsOS4wNSwxLjczLDEwLjEzLDAsMTQtMTUuNzQsMjEuNzctMzYuNDMsMjEuNzdDNzguNTQsMTA0LDM3LjU4LDc2LjYsMzcuNTgsNTguNDlhMTguNDUsMTguNDUsMCwwLDEsMS41MS03LjMzQzIyLjI3LDUyLC41LDU1LC41LDc0LjIyYzAsMzEuNDgsNzQuNTksNzAuMjgsMTMzLjY1LDcwLjI4LDQ1LjI4LDAsNTYuNy0yMC40OCw1Ni43LTM2LjY1LDAtMTIuNzItMTEtMjcuMTYtMzAuODMtMzUuNzgiLz48L3N2Zz4=
    mediatype: image/svg+xml
  image: quay.io/ocs-dev/ocs-registry:latest
  publisher: Red Hat
  sourceType: grpc
---
apiVersion: operators.coreos.com/v1alpha1
kind: Subscription
metadata:
  name: ocs-subscription
  namespace: openshift-storage
spec:
  channel: alpha
  config:
    resources: {}
  name: ocs-operator
  source: ocs-catalogsource
  sourceNamespace: openshift-marketplace
EOF


#validating OCS
wait_for_subscription "${NAMESPACE}" "ocs-subscription"


#Creating storage cluster
echo "INFO: Creating Storage Cluster"
create_storage_cluster

#Validate Openshift container storage
echo "INFO: Validating Openshift Container Storage Instances .."
validate_components "StorageCluster"
validate_components "CephBlockPool"
validate_components "BucketClass"
validate_components "BackingStore"

echo "INFO: **************** installOCS.sh script completed **********************"
