#!/bin/bash

export cluster_name=$1
export domain_name=$2
export openshift_user=$3
export openshift_password=$4
export namespace=$5

release_name="ace-db-quickstart"
echo "Release Name:" ${release_name}

echo "Logging to Openshift - https://api.${cluster_name}.${domain_name}:6443 .."
var=0
oc login "https://api.${cluster_name}.${domain_name}:6443" -u "$openshift_user" -p "$openshift_password" --insecure-skip-tls-verify=true
var=$?
echo "exit code: $var"

echo "Installing ACE Dashboard in ${namespace} .."
echo "Tracing is currently set to false"

cat << EOF | oc apply -f -
apiVersion: appconnect.ibm.com/v1beta1
kind: Dashboard
metadata:
  name: ${release_name}
  namespace: ${namespace}
spec:
  license:
    accept: true
    license: L-APEH-BPUCJK
    use: CloudPakForIntegrationNonProduction
  pod:
    containers:
      content-server:
        resources:
          limits:
            cpu: 250m
      control-ui:
        resources:
          limits:
            cpu: 250m
            memory: 250Mi
  replicas: 1
  storage:
    class: ''
    size: 5Gi
    type: ephemeral
  useCommonServices: true
  version: 11.0.0
EOF

echo "Validating ACE Dashboard installation.."
acedb=0
time=0
while [[ acedb -eq 0 ]]; do

	if [ $time -gt 5 ]; then
      		echo "Timed-out : ACE Dashboard Installation failed.."
      		exit 1
    	fi
	
	oc get pods -n ${namespace} | grep ${release_name} | grep Running 
	resp=$?
	if [[ resp -ne 0 ]]; then
		echo -e "No running pods found for ${release_name} Waiting.."
		time=$((time + 1))
		sleep 60
	else
    echo "ACE Dashboard Installation successful.."
		acedb=1;
	fi
	
done
