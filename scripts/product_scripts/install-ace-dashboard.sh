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

release_name="ace-db-quickstart"
replicas="1"
ace_policy_names="L-APEH-BPUCJK"
tracing_enabled="false"

ace_version="11.0.0"

# divider func will draw a line to make the logs section more distinct, easier to read
function divider() {
  echo -e "\n=====================================================================================================\n"
}

# script_notify func will trigger a notification email and optionally end script execution
function script_notify() {
  local status=$1
  sh email-notify.sh "${cluster_name}" "${domain_name}" "${release_name}" "${namespace}" "${user_email}" "${status}"
  if [ "$status" == ${FAILED} ]; then
    divider
    exit 1
  fi
}

divider
echo "Release Name: " ${release_name}
divider

# Login to OpenShift
var=0
echo "$ARROW Log In to Openshift - https://api.${cluster_name}.${domain_name}:6443..."
oc login "https://api.${cluster_name}.${domain_name}:6443" -u "$openshift_user" -p "$openshift_password" --insecure-skip-tls-verify=true
var=$?
echo "$INFO exit code: $var"

echo "$INFO INFO:  $(date +${TIME_FORMAT}) :: Installing ACE Dashboard in ${namespace} .."
echo "$INFO INFO:  $(date +${TIME_FORMAT}) :: Tracing is currently set to ${tracing_enabled}"

cat << EOF | oc apply -f -
apiVersion: appconnect.ibm.com/v1beta1
kind: Dashboard
metadata:
  name: ${release_name}
  namespace: ${namespace}
spec:
  license:
    accept: true
    license: ${ace_policy_names}
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
  replicas: ${replicas}
  storage:
    class: ''
    size: 5Gi
    type: ephemeral
  useCommonServices: true
  version: ${ace_version}
EOF

# Validate installation
echo "$INFO INFO:  $(date +${TIME_FORMAT}) :: Validating ACE Dashboard installation..."
acedb=0
time=0

while [[ acedb -eq 0 ]]; do

	if [ $time -gt 5 ]; then
    echo "$CROSS ERROR: $(date +${TIME_FORMAT}) :: Timed-out : $(date +${TIME_FORMAT}) :: ACE Dashboard Installation ${FAILED}..."
    script_notify ${FAILED}
  fi
	
	oc get pods -n ${namespace} | grep ${release_name} | grep Running 
	resp=$?
	if [[ resp -ne 0 ]]; then
		echo -e "$WARN INFO:  $(date +${TIME_FORMAT}) :: No running pods found for ${release_name} Waiting..."
		time=$((time + 1))
		sleep 60
	else
    echo -e "$TICK INFO:  $(date +${TIME_FORMAT}) :: ACE Dashboard Installation ${SUCCESSFUL}..."
    script_notify ${SUCCESSFUL}
		acedb=1;
	fi
	
done

echo -e "$INFO INFO:  $(date +${TIME_FORMAT}) :: ACE Integration Dashboard Installation took $(($SECONDS / 60 / 60 % 24)) hour(s) $(($SECONDS / 60 % 60)) minutes and $(($SECONDS % 60)) seconds."
divider

echo -e "$INFO INFO:  $(date +${TIME_FORMAT}) :: Proceeding to setup a sample Integration Servers..."
sh install-ace-server.sh ${CLUSTERNAME} ${DOMAINNAME} ${OPENSHIFTUSER} ${OPENSHIFTPASSWORD} ${namespace} ${ace_version} ${user_email}