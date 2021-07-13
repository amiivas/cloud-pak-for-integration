#!/bin/bash

export cluster_name=$1
export domain_name=$2
export namespace=$3
export oc_username=$4
export oc_password=$5
export apic_release_name=$6
export org=$7
export catalog=$8
export user=$9
export password=${10}

echo "Attempting to login $OPENSHIFTUSER to https://api.${cluster_name}.${domain_name}:6443 "
oc login "https://api.${cluster_name}.${domain_name}:6443" -u $oc_username -p $oc_password --insecure-skip-tls-verify=true
var=$?
echo "exit code: $var"
echo "2"

#Creating cluster endpoint
apic_server=$apic_release_name-mgmt-admin-$namespace.apps.$cluster_name.$domain_name

echo "APIC Admin Endpoint :: ${apic_server}"

#Getting Realms : Not needed as of now. taking default value
#apic identity-providers:list --scope admin --server ${apic_server}

if [[ "$user" == "" ]]; then
  echo "Using default user as admin"
  user=admin
fi
  
if [[ "$password" == "" ]]; then
	#Getting password for admin user 
	password=$(oc get secrets -n ${namespace} ${apic_release_name}-mgmt-admin-pass -ojsonpath='{.data.password}' | base64 --decode && echo "")
  #echo "Password retreived : ${password}"
fi

if [[ "$org" == "" ]]; then
  org=cts-demo
fi

if [[ "$catalog" == "" ]]; then
  catalog=sandbox
fi

#Accepting apic licenses
echo "Accepting apic licenses"
apic --accept-license
sleep 2
apic --live-help
sleep 2
#Logging to API Connect CMC as admin
apic login --username admin --password "${password}" --server ${apic_server} --realm admin/default-idp-1
echo
sleep 5
#Creating default user for API Manager
output=$(cat << EOF | apic users:create --server ${apic_server} --org ${user} --user-registry api-manager-lur -
username: apiadmin
email: amit.srivastav@cognizant.com
first_name: APIManager
last_name: Admin
password: cts@1234
EOF
)

echo ${output}
URL=$(echo ${output} | cut -d' ' -f 9)
owner_url="owner_url: ${URL}"
echo "Owner URL: ${URL}"

sleep 5
#Creating Provider Organization
orgoutput=$(cat << EOF | apic orgs:create --server ${apic_server} -
name: ${org}
title: ${org}
owner_url: ${URL}
EOF
)
sleep 5

echo "Output ${orgoutput}"

#Getting Organization Id
orgResp=$(apic orgs:get --server ${apic_server} ${org} --fields id --output -)
sleep 2
orgid=$(echo $orgResp | cut -d' ' -f 2)
echo "Org Id : $orgResp   : $orgid"
ret=0
if [[ "$orgid" == "" ]]; then
  orgResp=$(apic orgs:get --server ${apic_server} ${org} --fields id --output -)
  sleep 2
  orgid=$(echo $orgResp | cut -d' ' -f 2)
  echo "Org Id : $orgResp   : $orgid  retry $ret"
  ret=$((ret + 1))
  if [[ $ret == 2 ]]; then
    orgid="NotFound"
  fi
fi

#Getting Portal ID and Portal Service URL


portalResponse=$(apic portal-services:list --server ${apic_server} --org admin --availability-zone availability-zone-default)
sleep 5
portalURL=$(echo ${portalResponse} | cut -d' ' -f 2)

portalId=$(echo ${portalResponse} | cut -d'/' -f 10)

#Assigning Portal to ${catalog}
echo "Assigning portal services to ${catalog}"
apim_server=$apic_release_name-mgmt-api-manager-$namespace.apps.$cluster_name.$domain_name

portal_service_url=https://${apic_server}/api/orgs/${orgid}/portal-services/${portalId}
echo "Portal URL ${portal_service_url}"

#Creating Portal Endpoint
portal_endpoint=https://${apic_release_name}-ptl-portal-web-${namespace}.apps.${cluster_name}.${domain_name}/${org}/${catalog}

cat << EOF > portal_config.yaml
portal:
  type: drupal
  endpoint: >-
    ${portal_endpoint}
  portal_service_url: >-
    ${portal_service_url}
EOF

sleep 5


#Setting mail server
echo "Setting Demo Mail Server .. "

cat << EOF | apic mail-servers:create --org admin --server ${apic_server}  -
title: demo-email-server
name: demo-email-server
host: smtp.sendgrid.net
port: 587
credentials:
  username: apikey
  password: SG.Q2zQUTXTTcGqF6iTzhtVXA.V18213X6iHyHHbnMdJ3GoHW040zXkx9uQzkdv6qMTVk
EOF


sleep 1
mail_server=$(apic mail-servers:get --server  ${apic_server} --org admin demo-email-server --output - --fields url)
echo $mail_server
mail_server_url=$(echo $mail_server | cut -d' ' -f 3)
echo "mail server url : $mail_server_url"

echo "Updating cloud settings with email server ... "
cat << EOF > cloud_config.yaml
mail_server_url: ${mail_server_url}
email_sender:
  name: APIC Administrator
  address: amitsrikiet@gmail.com

EOF

apic cloud-settings:update --server ${apic_server} cloud_config.yaml
echo "Logging out admin from CMC"
apic logout --server ${apic_server}

sleep 5

echo "Logging as newly created user apiadmin in Organization ${org} in API Manager"
apic login --server ${apic_server} --username apiadmin --password "cts@1234" --realm provider/default-idp-2
echo

sleep 5
echo "Gateway available for the organizaton"
apic gateway-services:list --server ${apic_server} --scope org --org ${org}

echo "Updating catalog settings for portal services"
apic catalog-settings:update --org ${org} --server ${apic_server} --catalog ${catalog} portal_config.yaml

echo "Publishing Products ..."
apic products:publish --server ${apic_server} --org ${org} --catalog sandbox --accept-license --live-help products/cts-demo-apic-product_1.0.0.yaml
   
echo  "Uploading API in API Manager Drafts"
apic draft-apis:create --server ${apic_server} --org ${org} products/cts-demo-apic-api_1.0.0.yaml

sleep 4
apic logout --server ${apic_server}

#yes | sh publish-products.sh ${cluster_name} ${domain_name} ${namespace} ${apic_release_name} ${org} apiadmin "cts@1234"
