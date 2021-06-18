#!/bin/bash
export SUDOUSER=$1
export OPENSHIFTPASSWORD=$2
export namespace=$3
export STORAGEOPTION=$4
export ASSEMBLY=$5
export CLUSTERNAME=$6
export DOMAINNAME=$7
export OPENSHIFTUSER=$8
export entitlementKey=$9
export platformNavigatorReplicas=${10}
export capabilityAPIConnect=${11}
export capabilityAPPConnectDashboard=${12}
export capabilityAPPConenctDesigner=${13}
export capabilityAssetRepository=${14}
export capabilityOperationsDashboard=${15}
export runtimeMQ=${16}
export runtimeKafka=${17}
export runtimeAspera=${18}
export runtimeDataPower=${19}
export productInstallationPath=${20}
export storageAccountName=${21}
export user_email=${22}
export cloudpakVersion=${23}

#Pre-defined values
#TODO: Can be user-provided

maxWaitTime=600
maxTrials=2
currentTrial=1
storageClass="ocs-storagecluster-cephfs"

export asperaKey=''

export INSTALLERHOME=/home/$SUDOUSER/.ibm


export platformPassword="";

function openshift_login {
  var=0
  while [ $var -ne 0 ]; do
  echo "Attempting to login $OPENSHIFTUSER to https://api.${CLUSTERNAME}.${DOMAINNAME}:6443 "
  oc login "https://api.${CLUSTERNAME}.${DOMAINNAME}:6443" -u "$OPENSHIFTUSER" -p "$OPENSHIFTPASSWORD" --insecure-skip-tls-verify=true
  var=$?
  echo "exit code: $var"
done
}


#Print a formatted time in minutes and seconds from the given input in seconds
function output_time {
  SECONDS=${1}
  if((SECONDS>59));then
    printf "%d minutes, %d seconds" $((SECONDS/60)) $((SECONDS%60))
  else
    printf "%d seconds" "$SECONDS"
  fi
}

# retry the installation - either with uninstalling or not
# increments the number of trials
# only retry if maximum number of trials isn't reached yet
function retry {
  # boolean flag indicates whether to uninstall or not
  uninstall=${1}

  if [[ $uninstall == true ]]
  then
    # uninstall
    sh ./cp4i-uninstall.sh -n "${namespace}"
  fi

  # incermenent currentTrial
  currentTrial=$((currentTrial + 1))

  if [[ $currentTrial -gt $maxTrials ]]
    then
    echo "ERROR: Max Install Trials Reached, exiting now";
    exit 1
  else
    # recall install inscript with current trial
    echo "INFO: Attempt Trial Number ${currentTrial} to install";

    install
  fi
}

# Delete a subscription with the given name in the given namespace
function delete_subscription {
  NAMESPACE=${1}
  name=${2}
  echo "INFO: Deleting subscription $name from $NAMESPACE"
  SUBSCRIPTIONS=$(oc get subscriptions -n "${NAMESPACE}"  -o json |\
    jq -r ".items[] | select(.metadata.name==\"$name\") | .metadata.name "\
  )
  echo "DEBUG: Found subscriptions:"
  echo "$SUBSCRIPTIONS"

  # Get a unique list of install plans for subscriptions that are stuck in "UpgradePending"
  INSTALL_PLANS=$(oc get subscription -n "${NAMESPACE}"  -o json |\
    jq -r "[ .items[] | select(.metadata.name==\"$name\")| .status.installplan.name] | unique | .[]" \
  )
  echo "DEBUG: Associated installplans:"
  echo "$INSTALL_PLANS"

  # Get the csv
  CSV=$(oc get subscription -n "${NAMESPACE}" "${name}" -o json | jq -r .status.currentCSV)
  echo "DEBUG: Associated ClusterServiceVersion:"
  echo "$CSV"

  # Delete CSV
  oc delete csv -n "${NAMESPACE}" "$CSV"

  # Delete the InstallPlans
  oc delete installplans -n "${NAMESPACE}" "$INSTALL_PLANS"

  # Delete the Subscriptions
  oc delete subscriptions -n "${NAMESPACE}"  "$SUBSCRIPTIONS"
}

# wait for a subscription to be successfully installed
# takes the name and the namespace as input
# waits for the specified maxWaitTime - if that is exceeded the subscriptions is deleted and it returns 1
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
        delete_subscription "${NAMESPACE}" "${NAME}"
        SOURCE=$(oc get subscription -n "${NAMESPACE}" "${NAME}" -o json | jq -r ".spec.source");
        CHANNEL=$(oc get subscription -n "${NAMESPACE}" "${NAME}" -o json | jq -r ".spec.channel");
        #OPERNAME=$(oc get subscription -n "${NAMESPACE}" "${NAME}" -o json | jq -r ".spec.name");
        create_subscription "${SOURCE}" "${NAME}" "${CHANNEL}"
        return 1
      fi

      # wait
      sleep $wait_time
    fi
  done
  echo "INFO: $NAME has succeeded"
}


# create a subscriptions and wait for it to be in succeeded state - if it fails: retry ones
# if it fails 2 times retry the whole installation
# param namespace: the namespace the subscription is created in
# param source: the catalog source of the operator
# param name: name of the subscription
# param channel: channel to be used for the subscription
# param retried: indicate whether this subscription has failed before and this is the retry
function create_subscription {
  NAMESPACE=${1}
  SOURCE=${2}
  NAME=${3}
  CHANNEL=${4}
  RETRIED=${5:-false};
  SOURCE_NAMESPACE="openshift-marketplace"

  # create subscription itself
  cat <<EOF | oc apply -f -
apiVersion: operators.coreos.com/v1alpha1
kind: Subscription
metadata:
  name: ${NAME}
  namespace: ${NAMESPACE}
spec:
  channel: ${CHANNEL}
  installPlanApproval: Automatic
  name: ${NAME}
  source: ${SOURCE}
  sourceNamespace: ${SOURCE_NAMESPACE}
EOF

  # wait for it to succeed and retry if not
  wait_for_subscription "${NAMESPACE}" "${NAME}"
  if [[ "$?" != "0"   ]]
  then
    if [[ $RETRIED == true ]]
    then
      echo "ERROR: Failed to install subscription ${NAME} after retrial, deleting subscription.."
      delete_subscription "${NAMESPACE}" "${NAME}"
      return 1
    fi
    echo "INFO: retrying subscription ${NAME}";
    create_subscription "${NAMESPACE}" "${SOURCE}" "${NAME}" "${CHANNEL}" true
  fi
}

# install an instance of the platform navigator operator
# wait until it is ready - if it fails retry
function install_platform_navigator {
    
  cat <<EOF | oc apply -f -
apiVersion: integration.ibm.com/v1beta1
kind: PlatformNavigator
metadata:
  name: ${namespace}-navigator
  namespace: ${namespace}
spec:
  license:
    accept: true
    license: L-RJON-BXUPZ2
  mqDashboard: true
  replicas: ${platformNavigatorReplicas}
  storage:
    class: ${storageClass}
  version: 2021.1.1
EOF

  status=false;
  time=0
  #Maximum wait time for platform navigator to get created : 45 Minutes
  maximumWaitTime=2700
  while [[ "$status" == false ]]; do 
    
  
    # Waiting for platform navigator object to be ready
    
    currentStatus="$(oc get PlatformNavigator -n "${namespace}" "${namespace}"-navigator -o json | jq -r '.status.conditions[] | select(.type=="Ready").status')";
    
    if [ "${currentStatus}" != "True" ]
    then
      echo "INFO: Waiting for PlatformNavigator to be created. Waited ${time} seconds(s)."
      time=$((time + 60))
      sleep 60
    else
      status=true
    fi

    if [ $time -gt $maximumWaitTime ]; then
      echo "ERROR: Exiting installation as timeout waiting for PlatformNavigator to be created"
      return 1
    fi
 
  done
}


function wait_for_product {
  type=${1}
  release_name=${2}
  NAMESPACE=${3}
    time=0
    status=false;
  while [[ "$status" == false ]]; do
        currentStatus="$(oc get "${type}" -n "${NAMESPACE}" "${release_name}" -o json | jq -r '.status.conditions[] | select(.type=="Ready").status')";
        if [ "$currentStatus" == "True" ]
        then
          status=true
        fi

    if [ "$status" == false ]
    then
        currentStatus="$(oc get "${type}" -n "${NAMESPACE}" "${release_name}" -o json | jq -r '.status.phase')"

        if [ "$currentStatus" == "Ready" ] || [ "$currentStatus" == "Running" ] || [ "$currentStatus" == "Succeeded" ]
        then
          status=true
        fi
    fi

    echo "INFO: The ${type} status: $currentStatus"  
    if [ "$status" == false ]; then
      if [ $time -gt $maxWaitTime ]; then
        echo "ERROR: Exiting installation ${type}  object is not ready"
        return 1
      fi
    
      echo "INFO: Waiting for ${type} object to be ready. Waited ${time} second(s)."
  
      time=$((time + 5))
      sleep 5
    fi
  done
}


#function to install IBM Cloud Pak foundational services
function install_foundation_services {

  #using namespace as "common-service";
  
  echo "INFO: Creating namespace, OperatorGroup, and subscription"
  
  cat <<EOF | oc apply -f -
apiVersion: v1
kind: Namespace
metadata:
  name: common-service

---
apiVersion: operators.coreos.com/v1alpha2
kind: OperatorGroup
metadata:
  name: operatorgroup
  namespace: common-service
spec:
  targetNamespaces:
  - common-service

---
apiVersion: operators.coreos.com/v1alpha1
kind: Subscription
metadata:
  name: ibm-common-service-operator
  namespace: common-service
spec:
  channel: v3
  installPlanApproval: Automatic
  name: ibm-common-service-operator
  source: opencloud-operators
  sourceNamespace: openshift-marketplace 
EOF
  
  #Validating the status of ibm-common-service-operator
  wait_for_subscription common-service ibm-common-service-operator

  # wait for the Operand Deployment Lifecycle Manager to be installed
  wait_for_subscription ibm-common-services operand-deployment-lifecycle-manager-app
  
  # wait for CommonService to get succeeded
  wait_for_product CommonService common-service ibm-common-services
  
  #Changing the storage class to openshift cluster storage file system
  cat <<EOF | oc apply -f - 
apiVersion: operator.ibm.com/v3
kind: CommonService
metadata:
  name: common-service
  namespace: ibm-common-services
spec:
  storageClass: ocs-storagecluster-cephfs
EOF

echo "INFO: OperandRegistry Status:  $(oc get operandregistry -n ibm-common-services -o json | jq -r '.items[].status.phase')" 

#Installing IBM Cloud Pak foundational services operands 
  cat <<EOF | oc apply -f - 
apiVersion: operator.ibm.com/v1alpha1
kind: OperandRequest
metadata:
  name: common-service
  namespace: ibm-common-services
spec:
  requests:
    - operands:
        - name: ibm-cert-manager-operator
        - name: ibm-mongodb-operator
        - name: ibm-iam-operator
        - name: ibm-monitoring-exporters-operator
        - name: ibm-monitoring-prometheusext-operator
        - name: ibm-monitoring-grafana-operator
        - name: ibm-healthcheck-operator
        - name: ibm-management-ingress-operator
        - name: ibm-licensing-operator
        - name: ibm-commonui-operator
        - name: ibm-events-operator
        - name: ibm-ingress-nginx-operator
        - name: ibm-auditlogging-operator
        - name: ibm-platform-api-operator
        - name: ibm-zen-operator
      registry: common-service
EOF

  subscriptions=$(oc get subscription -n ibm-common-services -o json | jq -r ".items[].metadata.name")
  for subscription in ${subscriptions}; do
    wait_for_subscription ibm-common-services "${subscription}"
  done
}

#
#Main function to start installing Cloud Pak for Integration
#
function install {
  # -------------------- BEGIN INSTALLATION --------------------
  echo "INFO: Starting installation of Cloud Pak for Integration in $namespace for $SUDOUSER"

  echo "Attempting to login $OPENSHIFTUSER to https://api.${CLUSTERNAME}.${DOMAINNAME}:6443 "
  oc login "https://api.${CLUSTERNAME}.${DOMAINNAME}:6443" -u "$OPENSHIFTUSER" -p "$OPENSHIFTPASSWORD" --insecure-skip-tls-verify=true
  var=$?
  echo "exit code: $var"
  
  oc new-project "$namespace"
  # check if the project has been created - if not retry
  oc get project "$namespace"
  if [[ $? == 1 ]]
    then
      retry false
  fi

  # Create IBM Entitlement Key Secret
  oc create secret docker-registry ibm-entitlement-key \
      --docker-username=cp \
      --docker-password="$entitlementKey" \
      --docker-server=cp.icr.io \
      --namespace="${namespace}"

  # check if it has been created - if not retry
  oc get secret ibm-entitlement-key -n "$namespace"
  if [[ $? == 1 ]]
    then
      retry false
  fi

  #Create Open Cloud and IBM Cloud Operator CatalogSource
  cat <<EOF | oc apply -f -
apiVersion: operators.coreos.com/v1alpha1
kind: CatalogSource
metadata:
  name: opencloud-operators
  namespace: openshift-marketplace
spec:
  displayName: IBMCS Operators
  publisher: IBM
  sourceType: grpc
  image: docker.io/ibmcom/ibm-common-service-catalog:latest
  updateStrategy:
    registryPoll:
      interval: 45m
EOF


  cat <<EOF | oc apply -f -
apiVersion: operators.coreos.com/v1alpha1
kind: CatalogSource
metadata:
  name: ibm-operator-catalog
  namespace: openshift-marketplace
spec:
  displayName: IBM Operator Catalog
  image: 'icr.io/cpopen/ibm-operator-catalog:latest'
  publisher: IBM
  sourceType: grpc
  updateStrategy:
    registryPoll:
      interval: 45m
EOF

   # check if Operator catalog source has been created - if not retry
  oc get CatalogSource opencloud-operators -n openshift-marketplace
  if [[ $? == 1 ]]
    then
      retry false
  fi
  
  oc get CatalogSource ibm-operator-catalog -n openshift-marketplace
  if [[ $? == 1 ]]
    then
      retry false
  fi

   cat <<EOF | oc apply -f -
apiVersion: operators.coreos.com/v1
kind: OperatorGroup
metadata:
  name: ${namespace}-og
  namespace: ${namespace}
spec:
  targetNamespaces:
    - ${namespace}
EOF

  # check if Operator Group has been created
  oc get OperatorGroup "${namespace}"-og -n "${namespace}"
  if [[ $? != 0 ]]
    then
      retry false
  fi

  #Installing IBM Cloud Pak Foundational Services
  install_foundation_services
  echo "Validating IBM Common Services.."
  status=false
  time=0
  while [[ "$status" == false ]]; do

	if [ $time -gt 15 ]; then
      		echo "WARNING: IBM common services alert.."
			status=true
    	fi
	
	count=$(oc get pods -n ibm-common-services | wc -l)
	
  if [[ count -lt 49 ]]; then
		echo -e "INFO: Pods are still getting created for ${release_name} Waiting.."
		time=$((time + 1))
		status=false
		sleep 60
	else
    	echo "INFO: IBM Common Services reached to stable state.."
		status=true
	fi
  done
  
  #sleep 120
  
  #Accessing Cloud Pak console
  echo "INFO: IBM Cloud Pak foundational services console :: https://$(oc get route -n ibm-common-services cp-console -o jsonpath='{.spec.host}')"
  
  #Default user name and password
  echo "INFO: username :: $(oc -n ibm-common-services get secret platform-auth-idp-credentials -o jsonpath='{.data.admin_username}' | base64 -d && echo)  & password :: $(oc -n ibm-common-services get secret platform-auth-idp-credentials -o jsonpath='{.data.admin_password}' | base64 -d)"
  
  #Installing IBM Cloud Pak for Integration operator
  #create_subscription ${namespace} "ibm-operator-catalog" "ibm-cp-integration" "v1.2"
  
  create_subscription "${namespace}" "opencloud-operators" "ibm-common-service-operator" "v3"
  
  #create_subscription ${namespace} "ibm-operator-catalog" "ibm-cp-integration" "v1.2"
  #subscriptions=$(oc get subscription -n $namespace -o json | jq -r ".items[].metadata.name")
  #for subscription in ${subscriptions}; do
  #  echo -n "${subscription} "
  #  wait_for_subscription ${namespace} ${subscription}
  #done
  
  #echo "INFO: Installing CP4I version ${cloudpakVersion} operators..."
  create_subscription "${namespace}" "certified-operators" "couchdb-operator-certified" "v1.4"
  #the Aspera operator is not supported on OCP 4.7.
  #create_subscription ${namespace} "ibm-operator-catalog" "aspera-hsts-operator" "v1.2-eus"
  create_subscription "${namespace}" "ibm-operator-catalog" "datapower-operator" "v1.3"
  create_subscription "${namespace}" "ibm-operator-catalog" "ibm-appconnect" "v1.4"
  create_subscription "${namespace}" "ibm-operator-catalog" "ibm-eventstreams" "v2.3"
  #create_subscription ${namespace} "ibm-operator-catalog" "ibm-mq" "v1.5"
  create_subscription "${namespace}" "ibm-operator-catalog" "ibm-integration-asset-repository" "v1.2"
  # Apply the subscription for navigator. This needs to be before apic so apic knows it's running in cp4i
  create_subscription "${namespace}" "ibm-operator-catalog" "ibm-integration-platform-navigator" "v4.2"
  create_subscription "${namespace}" "ibm-operator-catalog" "ibm-apiconnect" "v2.2"
  create_subscription "${namespace}" "ibm-operator-catalog" "ibm-integration-operations-dashboard" "v2.2"
  
  # Instantiate Platform Navigator
  #echo "INFO: Instantiating Platform Navigator"
  install_platform_navigator

  status="$(oc get PlatformNavigator -n "${namespace}" "${namespace}"-navigator -o json | jq -r '.status.conditions[] | select(.type=="Ready").status')";
  
  echo "INFO: The platform navigator object status: ${status}"
  if [ "${status}" == "True" ]; then  
    # Printing the platform navigator object status
    route=$(oc get route -n "${namespace}" "${namespace}"-navigator-pn -o json | jq -r .spec.host);  
    echo "INFO: PLATFORM NAVIGATOR ROUTE IS: $route";
    echo "INFO: Plaform Navigator initial admin password : $(oc extract secret/platform-auth-idp-credentials -n ibm-common-services --to=-)";
  fi

  # Download Email script
  echo "INFO: Downloading email script...";
  curl "${productInstallationPath}"/email-notify.sh -o email-notify.sh
  chmod +x email-notify.sh 
  sh email-notify.sh "${CLUSTERNAME}" "${DOMAINNAME}" "CloudPakForIntegrationv${cloudpakVersion}" "${namespace}" "${user_email}" "Completed" 
}

install

exit 0
