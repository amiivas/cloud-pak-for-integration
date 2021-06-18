#!/bin/bash

export cluster_name=$1
export domain_name=$2
export namespace=$3
export apic_release_name=$4
export org=$5
export catalog=$6
export user=$6
export password=$7

#Creating consumer app file
echo "username: consumerapp">consumerapp.txt
echo "email: consumerapp@example.com">>consumerapp.txt
echo "first_name: Consumer">>consumerapp.txt
echo "last_name: Demo">>consumerapp.txt
echo "password: cts@1234">>consumerapp.txt

apic_server=$apic_release_name-mgmt-admin-$namespace.apps.$cluster_name.$domain_name

echo "APIC Admin Endpoint :: ${apic_server}"

if [[ "$user" == "" ]]; then
  echo "Using default user as admin"
  user=apiadmin
fi
  
if [[ "$password" == "" ]]; then
	#Getting password for admin user 
	password="cts@1234"
  #echo "Password retreived : ${password}"
fi

if [[ "$org" == "" ]]; then
  org=cts-demo
fi

if [[ "$catalog" == "" ]]; then
  catalog=sandbox
fi

apic login --server ${apic_server} --username ${user} --password ${password} --realm provider/default-idp-2

echo "Creating new user in sandbox catalog"

res=$(apic users:create --server ${apic_server} --org ${org} --user-registry sandbox-catalog consumerapp.txt)

sid=$(echo ${res} | cut -d' ' -f 4)

echo $sid

consumer_org_res=$(cat << EOF | apic consumer-orgs:create --server ${apic_server} --org ${org} --catalog ${catalog} -
name: cts-demo-consumer-org
title: cts-demo-consumer-org
owner_url: ${sid}
EOF
)

echo $consumer_org_res

#Creating new app in the consumer organization
app_res=$(cat << EOF | apic apps:create --consumer-org cts-demo-consumer-org --catalog ${catalog} --server ${apic_server} --org ${org} -
title: cts-consumer-app
EOF
)

echo "Consumer App response $app_res"

#Getting client id and secret 
credResp=$(apic credentials:get --server ${apic_server} --catalog ${catalog} --org ${org} --consumer-org cts-demo-consumer-org --app cts-consumer-app credential-for-cts-consumer-app --fields client_id,client_secret --output -)

echo "Credentials ... "
echo $credResp