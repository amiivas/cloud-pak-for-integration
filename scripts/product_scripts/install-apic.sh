#!/bin/bash

export cluster_name=$1
export domain_name=$2
export openshift_user=$3
export openshift_password=$4
export namespace=$5
export productInstallationPath=$6

release_name="apic"
echo "Release Name:" ${release_name}

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
  profile: n3xc4.m16
  version: 10.0.1.0
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
	
	count=$(oc get pods -n ${namespace} | grep ${release_name} | wc -l)
	resp=$?
	if [[ count -ne 35 ]]; then
		echo -e "Pods are still getting created for ${release_name} Waiting.."
		time=$((time + 1))
		sleep 60
	else
    		echo "API Connect Installation successful.."
		apic=1;
	fi
    
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
    	yes | sh create-provider-org.sh ${CLUSTERNAME} ${DOMAINNAME} ${namespace} ${OPENSHIFTUSER} ${OPENSHIFTPASSWORD} ${release_name}
    fi
	
	
done
