#!/bin/bash
export SUDOUSER=$1
export OPENSHIFTPASSWORD=$2
export STORAGEOPTION=$4
export ASSEMBLY=$5
export CLUSTERNAME=$6
export DOMAINNAME=$7
export OPENSHIFTUSER=$8
export namespace=$3
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

Pre-defined values
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
  oc login "https://api.${CLUSTERNAME}.${DOMAINNAME}:6443" -u $OPENSHIFTUSER -p $OPENSHIFTPASSWORD --insecure-skip-tls-verify=true
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
    printf "%d seconds" $SECONDS
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
    sh ./cp4i-uninstall.sh -n ${namespace}
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
  SUBSCRIPTIONS=$(oc get subscriptions -n ${NAMESPACE}  -o json |\
    jq -r ".items[] | select(.metadata.name==\"$name\") | .metadata.name "\
  )
  echo "DEBUG: Found subscriptions:"
  echo "$SUBSCRIPTIONS"

  # Get a unique list of install plans for subscriptions that are stuck in "UpgradePending"
  INSTALL_PLANS=$(oc get subscription -n ${NAMESPACE}  -o json |\
    jq -r "[ .items[] | select(.metadata.name==\"$name\")| .status.installplan.name] | unique | .[]" \
  )
  echo "DEBUG: Associated installplans:"
  echo "$INSTALL_PLANS"

  # Get the csv
  CSV=$(oc get subscription -n ${NAMESPACE} ${name} -o json | jq -r .status.currentCSV)
  echo "DEBUG: Associated ClusterServiceVersion:"
  echo "$CSV"

  # Delete CSV
  oc delete csv -n ${NAMESPACE} $CSV

  # Delete the InstallPlans
  oc delete installplans -n ${NAMESPACE} $INSTALL_PLANS

  # Delete the Subscriptions
  oc delete subscriptions -n ${NAMESPACE}  $SUBSCRIPTIONS
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
    csv=$(oc get subscription -n ${NAMESPACE} ${NAME} -o json | jq -r .status.currentCSV)
    wait=0
    if [[ "$csv" == "null" ]]; then
      echo "INFO: Waited for $(output_time $time), not got csv for subscription"
      wait=1
    else
      phase=$(oc get csv -n ${NAMESPACE} $csv -o json | jq -r .status.phase)
      if [[ "$phase" != "Succeeded" ]]; then
        echo "INFO: Waited for $(output_time $time), csv not in Succeeded phase, currently: $phase"
        wait=1
      fi
    fi

    # if subscriptions hasn't succeeded yet: wait
    if [[ "$wait" == "1" ]]; then
      ((time=time+$wait_time))
      if [ $time -gt $maxWaitTime ]; then
        echo "ERROR: Failed after waiting for $((maxWaitTime/60)) minutes"
        # delete subscription after maxWaitTime has exceeded
        delete_subscription ${NAMESPACE} ${NAME}
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
  SOURCE_namespace="openshift-marketplace"
  SUBSCRIPTION_NAME="${NAME}-${CHANNEL}-${SOURCE}-${SOURCE_namespace}"

  # create subscription itself
  cat <<EOF | oc apply -f -
apiVersion: operators.coreos.com/v1alpha1
kind: Subscription
metadata:
  name: ${SUBSCRIPTION_NAME}
  namespace: ${NAMESPACE}
spec:
  channel: ${CHANNEL}
  installPlanApproval: Automatic
  name: ${NAME}
  source: ${SOURCE}
  sourceNamespace: ${SOURCE_namespace}
EOF

  # wait for it to succeed and retry if not
  wait_for_subscription ${NAMESPACE} ${SUBSCRIPTION_NAME}
  if [[ "$?" != "0"   ]]; then
    if [[ $RETRIED == true ]]
    then
      echo "ERROR: Failed to install subscription ${NAME} after retrial, reinstalling now";
      retry true
    fi
    echo "INFO: retrying subscription ${NAME}";
    create_subscription ${NAMESPACE} ${SOURCE} ${NAME} ${CHANNEL} true
  fi
}

# install an instance of the platform navigator operator
# wait until it is ready - if it fails retry
function install_platform_navigator {
  RETRIED=${1:-false};
  time=0
while ! cat <<EOF | oc apply -f -
apiVersion: integration.ibm.com/v1beta1
kind: PlatformNavigator
metadata:
  name: ${namespace}-navigator
  namespace: ${namespace}
spec:
  license:
    accept: true
  mqDashboard: true
  replicas: ${platformNavigatorReplicas}
  version: 2020.3.1
EOF

  do
    if [ $time -gt $maxWaitTime ]; then
      echo "ERROR: Exiting installation as timeout waiting for PlatformNavigator to be created"
      return 1
    fi
    echo "INFO: Waiting for PlatformNavigator to be created. Waited ${time} seconds(s)."
    time=$((time + 1))
    sleep 60
  done

  # Waiting for platform navigator object to be ready
  echo "INFO: Waiting for platform navigator object to be ready"

  time=0
  while [[ "$(oc get PlatformNavigator -n ${namespace} ${namespace}-navigator -o json | jq -r '.status.conditions[] | select(.type=="Ready").status')" != "True" ]]; do
    echo "INFO: The platform navigator object status:"
    echo "INFO: $(oc get PlatformNavigator -n ${namespace} ${namespace}-navigator)"
    if [ $time -gt $maxWaitTime ]; then
      echo "ERROR: Exiting installation Platform Navigator object is not ready"
      if [[ $RETRIED == false ]]
      then
        echo "INFO: Retrying to install Platform Navigator"
        install_platform_navigator true
      else
      retry true
      fi
    fi

    echo "INFO: Waiting for platform navigator object to be ready. Waited ${time} second(s)."

    time=$((time + 60))
    sleep 60
  done
}


function wait_for_product {
  type=${1}
  release_name=${2}
    time=0
    status=false;
  while [[ "$status" == false ]]; do
        currentStatus="$(oc get ${type} -n ${namespace} ${release_name} -o json | jq -r '.status.conditions[] | select(.type=="Ready").status')";
        if [ "$currentStatus" == "True" ]
        then
          status=true
        fi

    if [ "$status" == false ]
    then
        currentStatus="$(oc get ${type} -n ${namespace} ${release_name} -o json | jq -r '.status.phase')"

        if [ "$currentStatus" == "Ready" ] || [ "$currentStatus" == "Running" ]
        then
          status=true
        fi
    fi



    echo "INFO: The ${type}   status:"
    echo "INFO: $(oc get ${type} -n ${namespace} ${release_name} )"
    if [ $time -gt $maxWaitTime ]; then
      echo "ERROR: Exiting installation ${type}  object is not ready"
      return 1
    fi

    echo "INFO: Waiting for ${type} object to be ready. Waited ${time} second(s)."

    time=$((time + 5))
    sleep 5
  done
}

function install {
  # -------------------- BEGIN INSTALLATION --------------------
  echo "INFO: 1111 Starting installation of Cloud Pak for Integration in $namespace for $SUDOUSER"
  echo "1"

  echo "Attempting to login $OPENSHIFTUSER to https://api.${CLUSTERNAME}.${DOMAINNAME}:6443 "
  oc login "https://api.${CLUSTERNAME}.${DOMAINNAME}:6443" -u $OPENSHIFTUSER -p $OPENSHIFTPASSWORD --insecure-skip-tls-verify=true
  var=$?
  echo "exit code: $var"
  echo "2"
  oc new-project $namespace
  # check if the project has been created - if not retry
  oc get project $namespace
  if [[ $? == 1 ]]
    then
      echo "3"
      retry false
  fi

  # Create IBM Entitlement Key Secret
  oc create secret docker-registry ibm-entitlement-key \
      --docker-username=cp \
      --docker-password=$entitlementKey \
      --docker-server=cp.icr.io \
      --namespace=${namespace}

  # check if it has been created - if not retry
  oc get secret ibm-entitlement-key -n $namespace
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
---
apiVersion: operators.coreos.com/v1alpha1
kind: CatalogSource
metadata:
  name: ibm-operator-catalog
  namespace: openshift-marketplace
spec:
  displayName: ibm-operator-catalog
  publisher: IBM Content
  sourceType: grpc
  image: docker.io/ibmcom/ibm-operator-catalog
  updateStrategy:
    registryPoll:
      interval: 45m
---
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
  oc get OperatorGroup ${namespace}-og -n ${namespace}
  if [[ $? != 0 ]]
    then
      retry false
  fi

  # install common services
  echo "INFO: Applying individual subscriptions for cp4i dependencies"
  create_subscription ${namespace} "opencloud-operators" "ibm-common-service-operator" "stable-v1"

  # wait for the Operand Deployment Lifecycle Manager to be installed
  wait_for_subscription ibm-common-services operand-deployment-lifecycle-manager-app
  if [[ $? != 0 ]]
    then
      retry true
  fi

  # install all the operators one by one
  echo "INFO: Installing CP4I operators..."
  create_subscription ${namespace} "certified-operators" "couchdb-operator-certified" "stable"
  create_subscription ${namespace} "ibm-operator-catalog" "ibm-cloud-databases-redis-operator" "v1.1"
  create_subscription ${namespace} "ibm-operator-catalog" "aspera-hsts-operator" "v1.1"
  #create_subscription ${namespace} "ibm-operator-catalog" "datapower-operator" "v1.1"
  create_subscription ${namespace} "ibm-operator-catalog" "ibm-appconnect" "v1.0"
  create_subscription ${namespace} "ibm-operator-catalog" "ibm-eventstreams" "v2.1"
  create_subscription ${namespace} "ibm-operator-catalog" "ibm-mq" "v1.1"
  create_subscription ${namespace} "ibm-operator-catalog" "ibm-integration-asset-repository" "v1.0"
  # Apply the subscription for navigator. This needs to be before apic so apic knows it's running in cp4i
  create_subscription ${namespace} "ibm-operator-catalog" "ibm-integration-platform-navigator" "v4.0"
  create_subscription ${namespace} "ibm-operator-catalog" "ibm-apiconnect" "v2.0"
  create_subscription ${namespace} "ibm-operator-catalog" "ibm-integration-operations-dashboard" "v2.0"

  # Instantiate Platform Navigator
  echo "INFO: Instantiating Platform Navigator"
  install_platform_navigator

  # Printing the platform navigator object status
  route=$(oc get route -n ${namespace} ${namespace}-navigator-pn -o json | jq -r .spec.host);
  #echo "INFO: The platform navigator object status:"
  echo "INFO: $(oc get PlatformNavigator -n ${namespace} ${namespace}-navigator)"
  echo "INFO: PLATFORM NAVIGATOR ROUTE IS: $route";

  # Check if the platform navigator UI is reachable
  response=$(curl -k -I "https://${route}")
  if [[ $response != *"200 OK"* ]]; then
    # if navigator ui is not there
    retry true
  fi

  # Download Email script
  echo "INFO: Downloading email script...";
  curl ${productInstallationPath}/email-notify.sh -o email-notify.sh
  chmod +x email-notify.sh

  echo "INFO: CP4I Installed Successfully on project ${namespace}"
  echo "${capabilityOperationsDashboard} + ${capabilityAPIConnect}"

  if [[ "$capabilityOperationsDashboard" == "true" ]]
  then
    echo "INFO: Installing Capability Operations Dashboard";
    sh ${deploymentScriptsPath}/release-tracing.sh -n ${namespace} -r operations-dashboard -f ${storageClass} -p -b gp2
    wait_for_product OperationsDashboard operations-dashboard
  fi

  if [[ "$capabilityAPIConnect" == "True" ]]
  then
    echo "INFO: Installing Capability API Connect";
    curl ${productInstallationPath}/install-apic.sh -o install-apic.sh
    chmod +x install-apic.sh
    sh install-apic.sh ${CLUSTERNAME} ${DOMAINNAME} ${OPENSHIFTUSER} ${OPENSHIFTPASSWORD} ${namespace} ${productInstallationPath}
  fi

  if [[ "$capabilityAPPConnectDashboard" == "True" ]]
  then
    echo "INFO: Installing Runtime App Connect Dashboard";
    curl ${productInstallationPath}/install-ace-dashboard.sh -o install-ace-dashboard.sh
    chmod +x install-ace-dashboard.sh
    curl ${productInstallationPath}/install-ace-server.sh -o install-ace-server.sh
    chmod +x install-ace-server.sh
    sh install-ace-dashboard.sh ${CLUSTERNAME} ${DOMAINNAME} ${OPENSHIFTUSER} ${OPENSHIFTPASSWORD} ${namespace} ${user_email}
  fi

  if [[ "$capabilityAPPConenctDesigner" == "True" ]]
  then
    echo "INFO: Installing Capability App Connect Designer";
    curl ${productInstallationPath}/install-ace-designer.sh -o install-ace-designer.sh
    chmod +x install-ace-designer.sh
    sh install-ace-designer.sh ${CLUSTERNAME} ${DOMAINNAME} ${OPENSHIFTUSER} ${OPENSHIFTPASSWORD} ${namespace}
  fi

  
  if [[ "$capabilityAssetRepository" == "true" ]]
  then
    echo "INFO: Installing Capability Asset Repository";
    curl ${productInstallationPath}/install-assetrepo.sh -o install-assetrepo.sh
    chmod +x install-assetrepo.sh
    sh install-assetrepo.sh ${CLUSTERNAME} ${DOMAINNAME} ${OPENSHIFTUSER} ${OPENSHIFTPASSWORD} ${namespace} latest ${storageAccountName}
  fi
  
  if [[ "$runtimeMQ" == "True" ]]
  then
    echo "INFO: Installing Runtime MQ";
    curl ${productInstallationPath}/install-mq.sh -o install-mq.sh
    chmod +x install-mq.sh
    sh install-mq.sh ${CLUSTERNAME} ${DOMAINNAME} ${OPENSHIFTUSER} ${OPENSHIFTPASSWORD} ${namespace} "QM_CP4I" "SingleInstance" false true
    #wait_for_product QueueManager mq
  fi
  
  
  if [[ "$runtimeKafka" == "True" ]]
  then
    echo "INFO: Installing Runtime Kafka..";
    curl ${productInstallationPath}/install-kafka.sh -o install-kafka.sh
    chmod +x install-kafka.sh
    sh install-kafka.sh ${CLUSTERNAME} ${DOMAINNAME} ${OPENSHIFTUSER} ${OPENSHIFTPASSWORD} ${namespace} "kafka-dev"
    #wait_for_product EventStreams kafka
  fi

  if [[ "$runtimeAspera" == "true" ]]
  then
    echo "INFO: Installing Runtime Aspera";
    sh ${deploymentScriptsPath}/release-aspera.sh -n ${namespace} -r aspera -p -c ${storageClass} -k ${asperaKey}
    wait_for_product IbmAsperaHsts aspera
  fi

  if [[ "$runtimeDataPower" == "true" ]]
  then
    echo "INFO: Installing Runtime DataPower";
    sh ${deploymentScriptsPath}/release-datapower.sh -n ${namespace} -r datapower -p -a admin
    wait_for_product DataPowerService datapower
  fi   
}

install

exit 0
