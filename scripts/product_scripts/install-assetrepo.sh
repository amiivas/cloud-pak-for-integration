#!/bin/bash

export cluster_name=$1
export domain_name=$2
export openshift_user=$3
export openshift_password=$4
export namespace=$5
export assetrepo_version=$6
export storage_account=$7


instance_name="assetrepo-dev"
storageclass_data="icp-assetrepo-data"
storageclass_metadata="icp-assetrepo-metadata"

if [[ "$assetrepo_version" == "" ]]; then
 	assetrepo_version="latest"
fi

echo "Checking name of Azure Storage Account in input, else set default"
if [[ "$storage_account" == "" ]]; then
 	storage_account="ctsicpstorageaccount"
fi


echo "Logging to Openshift - https://api.${cluster_name}.${domain_name}:6443 .."
var=0
oc login "https://api.${cluster_name}.${domain_name}:6443" -u "$openshift_user" -p "$openshift_password" --insecure-skip-tls-verify=true
var=$?
echo "exit code: $var"

echo "Creating prerequisites"
echo "**********************"
echo

echo "Creating Storage Class for AssetRepository Instance '${instance_name}' in Openshift project '${namespace}'"
echo "Creating Storage Class for AssetRepository Data"

cat << EOF | oc apply -f -
kind: StorageClass
apiVersion: storage.k8s.io/v1
metadata:
  name: ${storageclass_data}
  annotations:
    description: For Asset repo Data
  labels:
    environment: dev
provisioner: kubernetes.io/azure-file
parameters:
  skuName: Standard_LRS
  storageAccount: ${storage_account}
reclaimPolicy: Delete
allowVolumeExpansion: false
volumeBindingMode: Immediate
EOF



echo "Creating Storage Class for AssetRepository MetaData"

cat << EOF | oc apply -f -
kind: StorageClass
apiVersion: storage.k8s.io/v1
metadata:
  name: ${storageclass_metadata}
  annotations:
    description: For Asset repo Metadata
  labels:
    environment: dev
provisioner: kubernetes.io/azure-disk
parameters:
  kind: Managed
  storageaccounttype: Premium_LRS
  storageAccount: ${storage_account}
reclaimPolicy: Delete
allowVolumeExpansion: false
volumeBindingMode: WaitForFirstConsumer
EOF



echo "Creating cluster role and permissions so service account can create Container Storage keys"

oc create clusterrole system:azure-cloud-provider --verb=get,create --resource=secrets
oc create clusterrolebinding system:azure-cloud-provider --clusterrole=system:azure-cloud-provider --user=system:serviceaccount:kube-system:persistent-volume-binder


echo "Creating AssetRepository Instance ${instance_name} in ${namespace}"
echo "******************************************************************"


cat << EOF | oc apply -f -
apiVersion: integration.ibm.com/v1beta1
kind: AssetRepository
metadata:
  namespace: ${namespace}
  name: ${instance_name}
spec:
  license:
    accept: true
  replicas: 1
  storage:
    assetDataVolume:
      class: ${storageclass_data}
    couchVolume:
      class: ${storageclass_metadata}
  version: ${assetrepo_version}
EOF


echo "Checking for successful pod creation"
echo "****"

time=0
while [ $time -lt 5 ]
do
	sleep 60
	IFS=$'\n' read -r -d '' -a podstatus < <( oc get pod -n ${namespace} | grep assetrepo | awk '$3 ~ Running {print $3}')

	if [ ${#podstatus[@]} -eq 3 ]
		then
		echo "Asset repository installed successfully"
		echo "Asset Repository URL: https://${instance_name}-ibm-ar-${namespace}.apps.${cluster_name}.${domain_name}"
		exit 0
	else
		echo "Waiting for installation to complete."
		time=$((time + 1))
	fi
	
	if [ $time -eq 5 ]
	then
		echo "installation failed"
		exit 1
	fi
done