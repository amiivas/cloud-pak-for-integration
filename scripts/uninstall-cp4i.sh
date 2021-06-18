

namespace='integration'
removeCommonServices=true
scriptsPath="$(pwd)/cp4i-deployment";

while getopts 'cn:v' flag; do
  case "${flag}" in
  
    n) namespace="${OPTARG}" ;;
    c) removeCommonServices=false;;
  esac
done

if [ -z "$namespace" ]
then
      echo "Error: missing namespace flag, make sure to pass namespace, ex: '-n mynamespace'"
      exit 1;
fi
echo '\nNamespace: '$namespace "\n"

echo "Applying  'oc delete PlatformNavigator -n $namespace --all'\n"
oc delete PlatformNavigator -n $namespace --all
echo "Applying  'oc delete AssetRepository -n $namespace --all'\n"
oc delete AssetRepository -n $namespace --all
echo "Applying  'oc delete APIConnectCluster -n $namespace --all'\n"
oc delete APIConnectCluster -n $namespace --all
echo "Applying  'oc delete Dashboard -n $namespace --all'\n"
oc delete Dashboard -n $namespace --all
echo "Applying  'oc delete DataPowerService -n $namespace --all'\n"
oc delete DataPowerService -n $namespace --all
echo "Applying  'oc delete DesignerAuthoring -n $namespace --all'\n"
oc delete DesignerAuthoring -n $namespace --all
echo "Applying  'oc delete EventStreams -n $namespace --all'\n"
oc delete EventStreams -n $namespace --all
echo "Applying  'oc delete QueueManager -n $namespace --all'\n"
oc delete QueueManager -n $namespace --all

csvList=$(oc get csv -n ${namespace} -o json | jq -r '.items[] | .metadata.name' )

  for name in $csvList 
  do 
    if [[ $name == *"operand-deployment-lifecycle-manager"* ]]; then
            echo "FOUND"
                csvList=( "${csvList[@]/$name}")
            fi
  done


echo "Applying  'oc delete csv -n $namespace ${csvList}' \n"

oc delete csv -n $namespace ${csvList}
echo "Applying  'oc delete Subscription -n $namespace --all' \n"
oc delete Subscription -n $namespace --all

echo "Applying  'oc delete ConfigMap couchdb-release redis-release -n $namespace' \n"
oc delete ConfigMap couchdb-release redis-release -n $namespace

echo "Applying  'oc delete operatorgroup $namespace-og -n $namespace' \n"
oc delete operatorgroup $namespace-og -n $namespace

echo "Applying  'oc delete catalogsource -n openshift-marketplace opencloud-operators ibm-operator-catalog' \n"
oc delete catalogsource -n openshift-marketplace opencloud-operators ibm-operator-catalog

echo "Applying  'oc delete  secret -n ${namespace} ibm-entitlement-key \n"
oc delete  secret -n ${namespace} ibm-entitlement-key

if [[ $removeCommonServices == true ]]
then
echo "removing common services"
sh ${scriptsPath}/delete-common-services.sh
fi
sh ${scriptsPath}/delete-project.sh -n ${namespace};

