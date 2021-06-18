#!/bin/bash

export cluster_name=$1
export domain_name=$2
export openshift_user=$3
export openshift_password=$4
export namespace=$5

release_name="ace-designer-quickstart"
echo "Release Name:" ${release_name}

echo "Logging to Openshift - https://api.${cluster_name}.${domain_name}:6443 .."
var=0
oc login "https://api.${cluster_name}.${domain_name}:6443" -u "$openshift_user" -p "$openshift_password" --insecure-skip-tls-verify=true
var=$?
echo "exit code: $var"

echo "Installing ACE Designer in ${namespace} .."
echo "Tracing is currently set to false"

cat << EOF | oc apply -f -
apiVersion: appconnect.ibm.com/v1beta1
kind: DesignerAuthoring
metadata:
  name: ${release_name}
  namespace: ${namespace}
spec:
  couchdb:
    replicas: 1
    storage:
      class: managed-premium
      size: 10Gi
      type: persistent-claim
  designerFlowsOperationMode: local
  license:
    accept: true
    license: L-APEH-BPUCJK
    use: CloudPakForIntegrationNonProduction
  replicas: 1
  useCommonServices: true
  version: 11.0.0
EOF

echo "Validating ACE Designer installation.."
acedsn=0
time=0
while [[ acedsn -eq 0 ]]; do

	if [ $time -gt 5 ]; then
      		echo "Timed-out : ACE Designer Installation failed.."
      		exit 1
    	fi
	
	oc get pods -n ${namespace} | grep ${release_name} | grep Running 
	resp=$?
	if [[ resp -ne 0 ]]; then
		echo -e "No running pods found for ${release_name} Waiting.."
		time=$((time + 1))
		sleep 60
	else
    echo "ACE Designer Installation successful.."
		acedsn=1;
	fi
	
done

cat << EOF | oc apply -f -
apiVersion: appconnect.ibm.com/v1beta1
kind: IntegrationServer
metadata:
  name: ace-server-1
  namespace: icp
spec:
  adminServerSecure: true
  barURL: ''
  designerFlowsOperationMode: disabled
  license:
    accept: true
    license: L-APEH-BPUCJK
    use: CloudPakForIntegrationNonProduction
  replicas: 3
  router:
    timeout: 120s
  service:
    endpointType: http
  useCommonServices: true
  version: 11.0.0
  configurations:
    - des-quickstart-designer-sc
EOF
echo "ACE IntegrationServer creation successful.."
