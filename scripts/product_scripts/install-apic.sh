#!/bin/bash

export cluster_name=$1
export domain_name=$2
export openshift_user=$3
export openshift_password=$4
export namespace=$5
export productInstallationPath=$6
export user_email=$7

release_name="apic"
echo "Release Name:" ${release_name}
maxWaitTime=3600

function wait_for_product {
  type=${1}
  release_name=${2}
  NAMESPACE=${3}
  time=0
  status=false;
  while [[ "$status" == false ]]; do
        
	currentStatus="$(oc get "${type}" -n "${NAMESPACE}" "${release_name}" -o json | jq -r '.status.phase')"

	if [ "$currentStatus" == "Ready" ] || [ "$currentStatus" == "Running" ] || [ "$currentStatus" == "Succeeded" ]
	then
	  status=true
	fi
    

    echo "INFO: The ${type} status: $currentStatus"  
    if [ "$status" == false ]; then
      if [ $time -gt $maxWaitTime ]; then
        echo "ERROR: Exiting installation ${type}  object is not ready"
        return 1
      fi
    
      echo "INFO: Waiting for ${type} object to be ready. Waited ${time} second(s)."
  
      time=$((time + 60))
      sleep 60
    fi
  done
}


echo "Logging to Openshift - https://api.${cluster_name}.${domain_name}:6443 .."
var=0
oc login "https://api.${cluster_name}.${domain_name}:6443" -u "$openshift_user" -p "$openshift_password" --insecure-skip-tls-verify=true
var=$?
echo "exit code: $var"

echo "Installing API Connect in ${namespace} .."
echo "Tracing is currently set to false"

cat << EOF | oc apply -f -
apiVersion: apiconnect.ibm.com/v1beta1
kind: APIConnectCluster
metadata:
  labels:
    app.kubernetes.io/instance: apiconnect
    app.kubernetes.io/managed-by: ibm-apiconnect
    app.kubernetes.io/name: apiconnect-${namespace}
  name: ${release_name}
  namespace: ${namespace}
spec:
  license:
    accept: true
    use: nonproduction
    license: L-RJON-BZ5LMW
  profile: n1xc10.m48
  version: 10.0.2.0
  storageClassName: ocs-storagecluster-ceph-rbd
  gateway:
    apicGatewayServiceV5CompatibilityMode: true
EOF

echo "Validating API Connect installation.."
apic=0
time=0
while [[ apic -eq 0 ]]; do

	if [ $time -gt 3600 ]; then
      		echo "Timed-out : API Connect Installation failed.."
      		exit 1
    	fi
	
	
        gw_release_name=${release_name}	
        ptl_release_name=${release_name}
        mgmt_release_name=${release_name}
	apic_release_name=${release_name}
	wait_for_product ManagementCluster "${mgmt_release_name}-mgmt" "${namespace}"
	wait_for_product PortalCluster "${ptl_release_name}-ptl" "${namespace}"
	wait_for_product GatewayCluster "${gw_release_name}-gw" "${namespace}"
	
	echo "INFO: Waiting for APIConnectCluster to be in Ready state .."
	wait_for_product APIConnectCluster "${apic_release_name}" "${namespace}"
	
	echo "API Connect Installation successful.."
	apic=1;
	
    echo "INFO: Downloading email script...";
    curl "${productInstallationPath}"/email-notify.sh -o email-notify.sh
    chmod +x email-notify.sh 
    sh email-notify.sh "${cluster_name}" "${domain_name}" "API Connect" "${namespace}" "${user_email}"  "completed" ""
    
    if [[ apic -eq 1 ]]; then
    	curl ${productInstallationPath}/apic/createProviderOrganization.sh -o create-provider-org.sh
	curl ${productInstallationPath}/apic/publishProducts.sh -o publish-products.sh
	curl ${productInstallationPath}/apic/createSubscription.sh -o create-subscription.sh
	mkdir -p products
	cd products
	echo ${productInstallationPath}/apic/products
	curl ${productInstallationPath}/apic/products/cts-demo-apic-api_1.0.0.yaml -o cts-demo-apic-api_1.0.0.yaml
	curl ${productInstallationPath}/apic/products/cts-demo-apic-product_1.0.0.yaml -o cts-demo-apic-product_1.0.0.yaml
	cd ../
    	chmod +x create-provider-org.sh publish-products.sh create-subscription.sh
        yes | sh create-provider-org.sh ${cluster_name} ${domain_name} ${namespace} ${openshift_user} ${openshift_password} ${release_name}
    fi
	
	
done
