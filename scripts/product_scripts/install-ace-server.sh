#!/bin/bash

#**********************************************************************************************************************
#
#    Script Name : install-ace-server.sh
#    Description : This script will try to create a new integration server in the ACE capability installed
#           Args : cluster name        -- the clusture where the capabilities are installed
#                  domain name         -- the domain under which the capabilities are installed
#                  openshift user      -- openshift admin username
#                  openshift password  -- openshift admin password
#                  namespace           -- the namespace of the clusture
#                  ace version         -- version of the ace dashboard and compatible integration server
#                  user email          -- email id on which installing status to be sent
#         Author : Cognizant EAS-IPM
#          Email : 
#
#**********************************************************************************************************************


export cluster_name=$1
export domain_name=$2
export openshift_user=$3
export openshift_password=$4
export namespace=$5
export ace_version=$6
export user_email=$7

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

release_name="ace-is"
replicas="1"
ace_policy_names="L-APEH-BPUCJK"
tracing_enabled="false"

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

# Purpose of the script
echo "$INFO INFO:  $(date +${TIME_FORMAT}) :: Preparing to setup an Integration Server ${release_name} on ACE in ${namespace}..."
echo "$INFO INFO:  $(date +${TIME_FORMAT}) :: Tracing is currently set to ${tracing_enabled}"

# Installing Integration Server configuration YAML
cat << EOF | oc apply -f -
apiVersion: appconnect.ibm.com/v1beta1
kind: Configuration
metadata:
  name: smtp-conf
  namespace: ${namespace}
spec:
  data: c210cDo6Y29uZmlnU01UUCA4MzA4MDdiZDkyNDVhMyA5OWRhZWNkZWM1Nzc4ZQ==
  description: mqsisetdbparms SMTP
  type: setdbparms
---
apiVersion: appconnect.ibm.com/v1beta1
kind: IntegrationServer
metadata:
  name: ${release_name}
  namespace: ${namespace}
spec:
  adminServerSecure: false
  barURL: ''
  configurations: ["smtp-conf"]
  designerFlowsOperationMode: disabled
  disableRoutes: false
  license:
    accept: true
    license: ${ace_policy_names}
    use: CloudPakForIntegrationNonProduction
  pod:
    containers:
      runtime:
        resources:
          limits:
            cpu: 250m
            memory: 250Mi
          requests:
            cpu: 250m
            memory: 250Mi
  replicas: ${replicas}
  router:
    timeout: 120s
  service:
    endpointType: http
  useCommonServices: true
  version: ${ace_version}
  logFormat: json
  tracing:
    enabled: ${tracing_enabled}
    namespace: ${namespace}
EOF

if [[ "$?" != "0" ]]; then
  echo -e "$CROSS ERROR: $(date +${TIME_FORMAT}) :: Failed to apply Integration Server Configurations..."
  script_notify ${FAILED}
fi

# Validate installation
echo "$INFO INFO:  $(date +${TIME_FORMAT}) :: Validating ACE Integration Server ${release_name} setup..."
acedb=0
time=0

# Maximum wait time for Integration Server to be up and running is 5*60 seconds
while [[ acedb -eq 0 ]]; do
  # Maximum retries - 5 times
  if [ $time -gt 6 ]; then
    echo "$CROSS ERROR: $(date +${TIME_FORMAT}) :: Timed-out : ACE Integration Server ${release_name} setup ${FAILED}..."
    script_notify ${FAILED}
  fi
  # Detecting if integration server with the specified ${release_name} is found
  oc get integrationservers -n "${namespace}" | grep ${release_name} | grep Ready
  resp=$?
  if [[ resp -ne 0 ]]; then
    echo -e "$WARN WARN:  $(date +${TIME_FORMAT}) :: No running ACE Integration Server found for ${release_name} Waiting..."
    time=$((time + 1))
    sleep 60
  else
    echo -e "$TICK INFO:  $(date +${TIME_FORMAT}) :: ACE Integration Server ${release_name} setup ${SUCCESSFUL}..."
    script_notify ${SUCCESSFUL}
    acedb=1;
  fi
done
echo -e "$INFO INFO:  $(date +${TIME_FORMAT}) :: ACE Integration Server setup took $(($SECONDS / 60 / 60 % 24)) hour(s) $(($SECONDS / 60 % 60)) minutes and $(($SECONDS % 60)) seconds."
divider