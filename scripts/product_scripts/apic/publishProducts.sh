#!/bin/bash

export cluster_name=$1
export domain_name=$2
export namespace=$3
export apic_release_name=$4
export org=$5
export user=$6
export password=$7

if [[ "$org" == "" ]]; then
  org=cts-demo
fi

whoami

#Creating cluster endpoint
echo '************* Inside publish-products.sh ***************'
apic_server=$apic_release_name-mgmt-admin-$namespace.apps.$cluster_name.$domain_name
resp=$(apic --accept-license)
sleep 2
lh=$(apic --live-help)
sleep 2


echo "Logging to API Manager :: ${apic_server} for user ${user} and password ${password}"



sleep 5
products_folder_path="./products/"
cd ${products_folder_path}
apic login --server ${apic_server} --username ${user} --password ${password} --realm provider/default-idp-2
echo "Products Folder Path ${products_folder_path}" 
for FILE in *product*; 
do 
   if [[ -f "$FILE" ]]; then
     echo  "Publishing $FILE"
     
     echo "User logged in : " 
     apic me:get --server ${apic_server} --accept-license --live-help
     apic products:publish --server ${apic_server} --org ${org} --catalog sandbox --accept-license --live-help cts-demo-apic-product_1.0.0.yaml
     var=$?
     
     if [[ var -eq 0 ]]; then
       mkdir -p ../published
       mv $FILE ../published/.
     fi
   else 
     echo "No Products to publish !!."
   fi
done
#sleep 5
#echo "Uploading APIs in draft state in API Manager"
#for FILE in *; 
#do 
#   if [[ -f "$FILE" ]]; then
#     echo  "Uploading $FILE"
#     apic draft-apis:create --server ${apic_server} --org ${org} $FILE
#     var=$?
#     if [[ var -eq 0 ]]; then
#       mkdir -p ../draftapis
#       mv $FILE ../draftapis/.
#     fi
#   else 
#     echo "No APIs to upload !!."
#   fi
#done

