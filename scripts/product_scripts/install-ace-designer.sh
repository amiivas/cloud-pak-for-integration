#!/bin/bash

export cluster_name=$1
export domain_name=$2
export openshift_user=$3
export openshift_password=$4
export namespace=$5
export user_email=$6

# Declaring variables
SECONDS=0
ARROW=$'\xE2\x86\xAA  '
TICK=$'\xe2\x9c\x85 '
WARN=$'\xE2\x9A\xA0  '
CROSS=$'\xe2\x9d\x8c '
INFO=$'\xE2\x84\xB9  '

SUCCESSFUL="successful"
FAILED="failed"
TIME_FORMAT="%Y-%m-%d_%H-%M-%S"

release_name="ace-designer-quickstart"
LOG_FILE=${release_name}_$(date +%Y-%m-%d).log
replicas="1"
ace_policy_names="L-APEH-BPUCJK"
tracing_enabled="false"

# divider func will draw a line to make the logs section more distinct, easier to read
function divider() {
  echo -e "\n=====================================================================================================\n" 2>&1 | tee -a ${LOG_FILE}
}

# script_notify func will trigger a notification email and optionally end script execution
function script_notify() {
  local status=$1
  if [ "$status" == ${FAILED} ]; then
    sh email-notify.sh "${cluster_name}" "${domain_name}" "${release_name}" "${namespace}" "${user_email}" "${status}" "${LOG_FILE}"
    divider
    rm ${LOG_FILE}
    exit 1
  else
    sh email-notify.sh "${cluster_name}" "${domain_name}" "${release_name}" "${namespace}" "${user_email}" "${status}"
  fi
}

divider
echo "Release Name: " ${release_name} 2>&1 | tee -a ${LOG_FILE}
divider

# Login to OpenShift
var=0
echo "$ARROW Log In to Openshift - https://api.${cluster_name}.${domain_name}:6443..." 2>&1 | tee -a ${LOG_FILE}
oc login "https://api.${cluster_name}.${domain_name}:6443" -u "$openshift_user" -p "$openshift_password" --insecure-skip-tls-verify=true 2>&1 | tee -a ${LOG_FILE}
var=$?
echo "$INFO exit code: $var" 2>&1 | tee -a ${LOG_FILE}

# Purpose of the script
echo "$INFO INFO:  $(date +${TIME_FORMAT}) :: Installing ACE Designer in ${namespace}..." 2>&1 | tee -a ${LOG_FILE}
echo "$INFO INFO:  $(date +${TIME_FORMAT}) :: Tracing is currently set to ${tracing_enabled}" 2>&1 | tee -a ${LOG_FILE}

# Installing App Connect Designer configuration YAML
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
    license: ${ace_policy_names}
    use: CloudPakForIntegrationNonProduction
  replicas: 1
  useCommonServices: true
  version: 11.0.0
EOF

echo "$INFO INFO:  $(date +${TIME_FORMAT}) :: Validating ACE Designer installation..." 2>&1 | tee -a ${LOG_FILE}
acedsn=0
time=0
while [[ acedsn -eq 0 ]]; do
  # Maximum retries - 5 times
  if [ $time -gt 5 ]; then
    echo "$CROSS ERROR: $(date +${TIME_FORMAT}) :: Timed-out : ACE Designer Installation ${release_name} setup ${FAILED}..." 2>&1 | tee -a ${LOG_FILE}
    script_notify ${FAILED}
  fi
  # Detecting if integration server with the specified ${release_name} is found
	oc get pods -n ${namespace} | grep ${release_name} | grep Running 2>&1 | tee -a ${LOG_FILE}
	resp=$?
	if [[ resp -ne 0 ]]; then
    echo -e "$WARN WARN:  $(date +${TIME_FORMAT}) :: No running pods found for ${release_name} Waiting..." 2>&1 | tee -a ${LOG_FILE}
		time=$((time + 1))
		sleep 60
	else
    echo -e "$TICK INFO:  $(date +${TIME_FORMAT}) :: ACE Designer Installation ${SUCCESSFUL}..." 2>&1 | tee -a ${LOG_FILE}
    script_notify ${SUCCESSFUL}
		acedsn=1;
	fi
	
done

# Setting up Integration Server for App Connect Designer configuration YAML
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

echo -e "$TICK INFO:  $(date +${TIME_FORMAT}) :: ACE IntegrationServer creation ${SUCCESSFUL}..." 2>&1 | tee -a ${LOG_FILE}
echo -e "$INFO INFO:  $(date +${TIME_FORMAT}) :: ACE Designer setup took $(($SECONDS / 60 / 60 % 24)) hour(s) $(($SECONDS / 60 % 60)) minutes and $(($SECONDS % 60)) seconds." 2>&1 | tee -a ${LOG_FILE}
divider
rm ${LOG_FILE}