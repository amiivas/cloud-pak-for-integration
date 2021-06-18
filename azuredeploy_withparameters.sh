{
    "$schema": "http://schema.management.azure.com/schemas/2015-01-01/deploymentTemplate.json#",
    "contentVersion": "1.0.0.0",
    "parameters": {
        "_artifactsLocation": {
            "type": "string",
            "metadata": {
                "description": "The base URL where artifacts required by this template are located. When the template is deployed using the accompanying scripts, a private location in the subscription will be used and this value will be automatically generated."
            },
            "defaultValue": "https://raw.githubusercontent.com/amiivas/cloud-pak-for-integration/main/"
        },
        "_artifactsLocationSasToken": {
            "type": "securestring",
            "metadata": {
                "description": "Token for the base URL where artifacts required by this template are located. When the template is deployed using the accompanying scripts, a private location in the subscription will be used and this value will be automatically generated."
            },
            "defaultValue": ""
        },
        "location": {
            "type": "string",
            "metadata": {
                "description": "Region where the resources should be created in"
            },
            "defaultValue": "[resourceGroup().location]"
        },
        "aadClientId": {
            "type": "string",
            "defaultValue": "05da0fdd-4b06-422c-93db-cba6860b7876",
            "metadata": {
                "description": "Azure AD Client ID"
            }
        },
        "aadClientSecret": {
            "type": "securestring",
            "defaultValue": "0bbo.J0y6-FWIKXMj8AX_98VNJ1r4k.H-I",
            "metadata": {
                "description": "Azure AD Client Secret"
            }
        },
        "adminUsername": {
            "type": "string",
            "minLength": 4,
			"defaultValue": "azureuser",
            "metadata": {
                "description": "Administrator username on Bastion VM"
            }
        },
        "bastionVmSize": {
            "type": "string",
            "defaultValue": "Standard_D4as_v4",
            "metadata": {
                "description": "Bastion Host VM size. Use VMs with Premium Storage support only."
            }
        },
        "sshPublicKey": {
            "type": "string",
			"defaultValue": "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQC2hvoJmT4XVwdPQFirsxnJdRJcmu9inWDYyYI4FbgsWqrQsh0t/l1fTutGJ8DimwTgN9HcDuMrAJhVf3e83/OrZWxoU7xaHkUeTuvnG3fPxiQWwRDRnrPE1w5vTGaLerE5NC2kx2lobvPHj3MeXYQZSFLNBwHvuTA1p6rR/MdLK7jP6g1MbqMAtyh0xZoBlJxopx5w/hA/bIr7PNXzYWwz+Lh4ZpImcHp+XX2vHfQ+5wY3dRUFE7GkTBXhWIeEZOoDo3A4f46iMMJxTffgIZaGV/BiloWHoyprst4dFeLz9KRPSnSjKGI/7PcScMsKvJtvQhDVuUwH/nWRygQ/pswF azureuser@cloudpak-bastion-vm",
            "metadata": {
                "description": "SSH public key for all VMs"
            }
        },
        "masterInstanceCount": {
            "type": "int",
            "defaultValue": 3,
            "allowedValues": [
                3,
                5
            ],
            "metadata": {
                "description": "Number of OpenShift masters."
            }
        },
        "workerInstanceCount": {
            "type": "int",
            "defaultValue": 3,
            "allowedValues": [
                3,
                4,
                5,
                6,
                7,
                8,
                9,
                10
            ],
            "metadata": {
                "description": "Number of OpenShift nodes"
            }
        },
        "masterVmSize": {
            "type": "string",
            "defaultValue": "Standard_D4as_v4",
            "metadata": {
                "description": "OpenShift Master VM size. Use VMs with Premium Storage support only."
            }
        },
        "workerVmSize": {
            "type": "string",
            "defaultValue": "Standard_D16as_v4",
            "metadata": {
                "description": "OpenShift Node VM(s) size. Use VMs with Premium Storage support only."
            }
        },
        "newOrExistingNetwork": {
            "type": "string",
            "defaultValue": "new",
            "allowedValues": [
                "new",
                "existing"
            ],
            "metadata": {
                "description": "Deploy in new cluster or in existing cluster. If existing cluster, make sure the new resources are in the same zone"
            }
        },
        "existingVnetResourceGroupName": {
            "type": "string",
            "defaultValue": "[resourceGroup().name]",
            "metadata": {
                "description": "Resource Group for Existing Vnet."
            }
        },
        "virtualNetworkName": {
            "type": "string",
            "defaultValue": "icp-auto-vnet",
            "metadata": {
                "description": "Name of new or existing virtual network"
            }
        },
        "virtualNetworkCIDR": {
            "type": "array",
            "defaultValue": [
                "10.0.4.0/22"
            ],
            "metadata": {
                "description": "VNet Address Prefix. Minimum address prefix is /24"
            }
        },
        "masterSubnetName": {
            "type": "string",
            "defaultValue": "masterSubnet",
            "metadata": {
                "description": "Name of new or existing master subnet"
            }
        },
        "masterSubnetPrefix": {
            "type": "string",
            "defaultValue": "10.0.5.0/24",
            "metadata": {
                "description": "Master subnet address prefix"
            }
        },
        "workerSubnetName": {
            "type": "string",
            "defaultValue": "workerSubnet",
            "metadata": {
                "description": "Name of new or existing worker subnet"
            }
        },
        "workerSubnetPrefix": {
            "type": "string",
            "defaultValue": "10.0.6.0/24",
            "metadata": {
                "description": "Worker subnet address prefix"
            }
        },
        "bastionSubnetName": {
            "type": "string",
            "defaultValue": "bastionSubnet",
            "metadata": {
                "description": "Name of new or existing bastion subnet"
            }
        },
        "bastionSubnetPrefix": {
            "type": "string",
            "defaultValue": "10.0.4.0/27",
            "metadata": {
                "description": "Worker subnet address prefix"
            }
        },
        "singleZoneOrMultiZone": {
            "type": "string",
            "defaultValue": "az",
            "allowedValues": [
                "az",
                "noha"
            ],
            "metadata": {
                "description": "Deploy to a Single AZ or multiple AZs"
            }
        },
        "dnsZone": {
            "type": "string",
			"defaultValue": "cloudpak-ipm.com",
            "metadata": {
                "description": "Domain name created with the App Service"
            }
        },
        "dnsZoneRG": {
            "type": "string",
			"defaultValue": "icp4i-rg",
            "metadata": {
                "description": "Resource Group that contains the domain name"
            }
        },
        "pullSecret": {
            "type": "securestring",
            "minLength": 1,
            "metadata": {
                "description": "Openshift PullSecret JSON Blob"
            }
        },
        "clusterName": {
            "type": "string",
            "defaultValue": "cp-cluster",
            "metadata": {
                "description": "Cluster resources prefix"
            }
        },
        "openshiftUsername": {
            "type": "string",
			"defaultValue": "kubeadmin",
            "metadata": {
                "description": "OpenShift login username"
            }
        },
        "openshiftPassword": {
            "type": "securestring",
            "minLength": 8,
            "metadata": {
                "description": "OpenShift login password"
            }
        },
        "enableFips": {
            "type": "bool",
            "defaultValue": false,
            "metadata": {
                "description": "Enable FIPS encryption"
            }
        },
        "storageOption": {
            "type": "string",
            "defaultValue": "none",
            "allowedValues": [
                "portworx",
                "nfs",
                "none"
            ]
        },
        "enableNfsBackup": {
            "type": "bool",
            "defaultValue": false,
            "allowedValues": [
                true,
                false
            ],
            "metadata": {
                "description": "Enable Backup on NFS node"
            }
        },
        "dataDiskSize": {
            "type": "int",
            "defaultValue": 1024,
            "allowedValues": [
                512,
                1024,
                2048
            ],
            "metadata": {
                "description": "Size of Datadisk in GB for NFS storage"
            }
        },
        "privateOrPublicEndpoints": {
            "type": "string",
            "defaultValue": "public",
            "allowedValues": [
                "public",
                "private"
            ],
            "metadata": {
                "description": "Public or private facing endpoints"
            }
        },
        "projectName": {
            "type": "string",
            "defaultValue": "icp",
            "metadata": {
                "description": "Openshift Namespace to deploy project"
            }
        },
        "apiKey": {
            "type": "securestring",
            "metadata": {
                "description": "IBM Container Registry API Key. See README on how to obtain this"
            }
        },
        "cloudPakLicenseAgreement": {
            "type": "string",
            "defaultValue": "reject",
            "allowedValues": [
                "accept",
                "reject"
            ],
            "metadata": {
                "description": "Accept License Agreement: https://ibm.biz/Bdq6KP"
            }
        }
    },
    "variables": {
        "networkResourceGroup": "[parameters('existingVnetResourceGroupName')]",
        "redHatTags": {
            "app": "OpenshiftContainerPlatform",
            "version": "4.6.x",
            "platform": "AzurePublic"
        },
        "imageReference": {
            "publisher": "RedHat",
            "offer": "RHEL",
            "sku": "7-RAW",
            "version": "latest"
        },
        "bastionHostname": "bastionNode",
        "nfsHostname": "nfsNode",
        "nfsVmSize": "Standard_D4as_v4",
        "workerSecurityGroupName": "worker-nsg",
        "masterSecurityGroupName": "master-nsg",
        "bastionSecurityGroupName": "bastion-nsg",
        "diagStorageAccountName": "[concat('diag', uniqueString(resourceGroup().id))]",
        "bastionPublicIpDnsLabel": "[concat('bastiondns', uniqueString(resourceGroup().id))]",
        "sshKeyPath": "[concat('/home/', parameters('adminUsername'), '/.ssh/authorized_keys')]",
        "clusterNodeDeploymentTemplateUrl": "[uri(parameters('_artifactsLocation'), concat('nested/clusternode.json', parameters('_artifactsLocationSasToken')))]",
        "openshiftDeploymentTemplateUrl": "[uri(parameters('_artifactsLocation'), concat('nested/openshiftdeploy.json', parameters('_artifactsLocationSasToken')))]",
        "preloadImagesDeploymentTemplateUrl": "[uri(parameters('_artifactsLocation'), concat('nested/preloadimagesdeploy.json', parameters('_artifactsLocationSasToken')))]",
        "openshiftDeploymentScriptUrl": "[uri(parameters('_artifactsLocation'), concat('scripts/deployOpenShift.sh', parameters('_artifactsLocationSasToken')))]",
        "cloudPakDeploymentTemplateUrl": "[uri(parameters('_artifactsLocation'), concat('nested/cloudpakdeploy.json', parameters('_artifactsLocationSasToken')))]",
        "cloudPakDeploymentScriptUrl": "[uri(parameters('_artifactsLocation'), concat('scripts/deployCloudPak.sh', parameters('_artifactsLocationSasToken')))]",
        "cloudPakConfigScriptFileName": "openshiftCloudPakConfig.sh",
        "cloudPakConfigScriptUrl": "[uri(parameters('_artifactsLocation'), concat('scripts/openshiftCloudPakConfig.sh', parameters('_artifactsLocationSasToken')))]",
        "nfsInstallScriptUrl": "[uri(parameters('_artifactsLocation'), concat('scripts/setup-nfs.sh', parameters('_artifactsLocationSasToken')))]",
        "openshiftDeploymentScriptFileName": "deployOpenShift.sh",
        "cloudPakDeploymentScriptFileName": "deployCloudPak.sh",
        "uploadImagesScriptFileName": "uploadImages.sh",
        "uploadImagesScriptUrl": "[uri(parameters('_artifactsLocation'), concat('scripts/uploadImages.sh', parameters('_artifactsLocationSasToken')))]",
        "nfsInstallScriptFileName": "setup-nfs.sh",
        "vaultName": "[concat(variables('nfsHostname'), '-vault')]",
        "backupFabric": "Azure",
        "backupPolicyName": "DefaultPolicy",
        "protectionContainer": "[concat('iaasvmcontainer;iaasvmcontainerv2;', resourceGroup().name, ';', variables('nfsHostname'))]",
        "protectedItem": "[concat('vm;iaasvmcontainerv2;', resourceGroup().name, ';', variables('nfsHostname'))]",
        "deployOpenshiftExt": "[concat('Microsoft.Compute/virtualMachines/', variables('bastionHostname'), '/extensions/deployOpenshift')]"
    },
    "resources": [
        {
            "type": "Microsoft.Resources/deployments",
            "apiVersion": "2019-05-01",
            "name": "pid-06f07fff-296b-5beb-9092-deab0c6bb8ea",
            "properties": {
                "mode": "Incremental",
                "template": {
                    "$schema": "https://schema.management.azure.com/schemas/2015-01-01/deploymentTemplate.json#",
                    "contentVersion": "1.0.0.0",
                    "resources": []
                }
            }
        },
        {
            "condition": "[equals(parameters('newOrExistingNetwork'), 'new')]",
            "type": "Microsoft.Network/virtualNetworks",
            "apiVersion": "2019-09-01",
            "name": "[parameters('virtualNetworkName')]",
            "location": "[parameters('location')]",
            "tags": {
                "displayName": "VirtualNetwork",
                "app": "[variables('redHatTags').app]",
                "version": "[variables('redHatTags').version]",
                "platform": "[variables('redHatTags').platform]"
            },
            "properties": {
                "addressSpace": {
                    "addressPrefixes": "[parameters('virtualNetworkCIDR')]"
                },
                "subnets": [
                    {
                        "name": "[parameters('bastionSubnetName')]",
                        "properties": {
                            "addressPrefix": "[parameters('bastionSubnetPrefix')]",
                            "networkSecurityGroup": {
                                "id": "[resourceId('Microsoft.Network/networkSecurityGroups/', variables('bastionSecurityGroupName'))]"
                            }
                        }
                    },
                    {
                        "name": "[parameters('masterSubnetName')]",
                        "properties": {
                            "addressPrefix": "[parameters('masterSubnetPrefix')]",
                            "networkSecurityGroup": {
                                "id": "[resourceId('Microsoft.Network/networkSecurityGroups/', variables('masterSecurityGroupName'))]"
                            }
                        }
                    },
                    {
                        "name": "[parameters('workerSubnetName')]",
                        "properties": {
                            "addressPrefix": "[parameters('workerSubnetPrefix')]",
                            "networkSecurityGroup": {
                                "id": "[resourceId('Microsoft.Network/networkSecurityGroups/', variables('workerSecurityGroupName'))]"
                            }
                        }
                    }
                ]
            },
            "dependsOn": [
                "[variables('bastionSecurityGroupName')]",
                "[variables('masterSecurityGroupName')]",
                "[variables('workerSecurityGroupName')]"
            ]
        },
        {
            "type": "Microsoft.Network/publicIPAddresses",
            "apiVersion": "2019-09-01",
            "name": "[variables('bastionPublicIpDnsLabel')]",
            "location": "[parameters('location')]",
            "sku": {
                "name": "Standard"
            },
            "tags": {
                "displayName": "BastionPublicIP",
                "app": "[variables('redHatTags').app]",
                "version": "[variables('redHatTags').version]",
                "platform": "[variables('redHatTags').platform]"
            },
            "properties": {
                "publicIPAllocationMethod": "Static",
                "dnsSettings": {
                    "domainNameLabel": "[variables('bastionPublicIpDnsLabel')]"
                }
            }
        },
        {
            "type": "Microsoft.Network/networkInterfaces",
            "apiVersion": "2019-09-01",
            "name": "[concat(variables('bastionHostname'), '-nic')]",
            "location": "[parameters('location')]",
            "dependsOn": [
                "[resourceId('Microsoft.Network/virtualNetworks/', parameters('virtualNetworkName'))]",
                "[resourceId('Microsoft.Network/networkSecurityGroups/', variables('bastionSecurityGroupName'))]",
                "[resourceId('Microsoft.Network/publicIPAddresses/', variables('bastionPublicIpDnsLabel'))]"
            ],
            "tags": {
                "displayName": "BastionNetworkInterface",
                "app": "[variables('redHatTags').app]",
                "version": "[variables('redHatTags').version]",
                "platform": "[variables('redHatTags').platform]"
            },
            "properties": {
                "ipConfigurations": [
                    {
                        "name": "[concat(variables('bastionHostname'), 'ipconfig')]",
                        "properties": {
                            "privateIPAllocationMethod": "Dynamic",
                            "subnet": {
                                "id": "[resourceId(variables('networkResourceGroup'), 'Microsoft.Network/virtualNetworks/subnets', parameters('virtualNetworkName'), parameters('bastionSubnetName'))]"
                            },
                            "publicIPAddress": {
                                "id": "[resourceId('Microsoft.Network/publicIPAddresses', variables('bastionPublicIpDnsLabel'))]"
                            }
                        }
                    }
                ],
                "networkSecurityGroup": {
                    "id": "[resourceId('Microsoft.Network/networkSecurityGroups', variables('bastionSecurityGroupName'))]"
                }
            }
        },
        {
            "condition": "[equals(parameters('storageOption'), 'nfs')]",
            "type": "Microsoft.Network/networkInterfaces",
            "apiVersion": "2019-09-01",
            "name": "[concat(variables('nfsHostname'), '-nic')]",
            "location": "[parameters('location')]",
            "dependsOn": [
                "[resourceId('Microsoft.Network/virtualNetworks/', parameters('virtualNetworkName'))]",
                "[resourceId('Microsoft.Network/networkSecurityGroups/', variables('workerSecurityGroupName'))]"
            ],
            "tags": {
                "displayName": "NFSNetworkInterface",
                "app": "[variables('redHatTags').app]",
                "version": "[variables('redHatTags').version]",
                "platform": "[variables('redHatTags').platform]"
            },
            "properties": {
                "ipConfigurations": [
                    {
                        "name": "[concat(variables('nfsHostname'), 'ipconfig')]",
                        "properties": {
                            "privateIPAllocationMethod": "Dynamic",
                            "subnet": {
                                "id": "[resourceId(variables('networkResourceGroup'), 'Microsoft.Network/virtualNetworks/subnets', parameters('virtualNetworkName'), parameters('workerSubnetName'))]"
                            }
                        }
                    }
                ],
                "networkSecurityGroup": {
                    "id": "[resourceId('Microsoft.Network/networkSecurityGroups', variables('workerSecurityGroupName'))]"
                }
            }
        },
        {
            "type": "Microsoft.Network/networkSecurityGroups",
            "apiVersion": "2019-09-01",
            "name": "[variables('bastionSecurityGroupName')]",
            "location": "[parameters('location')]",
            "tags": {
                "displayName": "BastionNSG",
                "app": "[variables('redHatTags').app]",
                "version": "[variables('redHatTags').version]",
                "platform": "[variables('redHatTags').platform]"
            },
            "properties": {
                "securityRules": [
                    {
                        "name": "allowSSHin_all",
                        "properties": {
                            "description": "Allow SSH in from all locations",
                            "protocol": "Tcp",
                            "sourcePortRange": "*",
                            "destinationPortRange": "22",
                            "sourceAddressPrefix": "*",
                            "destinationAddressPrefix": "*",
                            "access": "Allow",
                            "priority": 100,
                            "direction": "Inbound"
                        }
                    }
                ]
            }
        },
        {
            "type": "Microsoft.Resources/deployments",
            "apiVersion": "2019-05-01",
            "name": "BastionVmDeployment",
            "dependsOn": [
                "[resourceId('Microsoft.Network/networkInterfaces', concat(variables('bastionHostname'), '-nic'))]"
            ],
            "properties": {
                "mode": "Incremental",
                "templateLink": {
                    "uri": "[variables('clusterNodeDeploymentTemplateUrl')]",
                    "contentVersion": "1.0.0.0"
                },
                "parameters": {
                    "location": {
                        "value": "[parameters('location')]"
                    },
                    "sshKeyPath": {
                        "value": "[variables('sshKeyPath')]"
                    },
                    "sshPublicKey": {
                        "value": "[parameters('sshPublicKey')]"
                    },
                    "dataDiskSize": {
                        "value": "[parameters('dataDiskSize')]"
                    },
                    "adminUsername": {
                        "value": "[parameters('adminUsername')]"
                    },
                    "vmSize": {
                        "value": "[parameters('bastionVmSize')]"
                    },
                    "hostname": {
                        "value": "[variables('bastionHostname')]"
                    },
                    "role": {
                        "value": "bootnode"
                    },
                    "vmStorageType": {
                        "value": "Premium_LRS"
                    },
                    "imageReference": {
                        "value": "[variables('imageReference')]"
                    },
                    "redHatTags": {
                        "value": "[variables('redHatTags')]"
                    }
                }
            }
        },
        {
            "type": "Microsoft.Network/networkSecurityGroups",
            "apiVersion": "2019-09-01",
            "name": "[variables('masterSecurityGroupName')]",
            "location": "[parameters('location')]",
            "tags": {
                "displayName": "MasterNSG",
                "app": "[variables('redHatTags').app]",
                "version": "[variables('redHatTags').version]",
                "platform": "[variables('redHatTags').platform]"
            },
            "properties": {
                "securityRules": [
                    {
                        "name": "allowHTTPS_all",
                        "properties": {
                            "description": "Allow HTTPS connections from all locations",
                            "protocol": "Tcp",
                            "sourcePortRange": "*",
                            "destinationPortRange": "6443",
                            "sourceAddressPrefix": "*",
                            "destinationAddressPrefix": "*",
                            "access": "Allow",
                            "priority": 200,
                            "direction": "Inbound"
                        }
                    }
                ]
            }
        },
        {
            "type": "Microsoft.Network/networkSecurityGroups",
            "apiVersion": "2019-09-01",
            "name": "[variables('workerSecurityGroupName')]",
            "location": "[parameters('location')]",
            "tags": {
                "displayName": "WorkerNSG",
                "app": "[variables('redHatTags').app]",
                "version": "[variables('redHatTags').version]",
                "platform": "[variables('redHatTags').platform]"
            },
            "properties": {
                "securityRules": [
                    {
                        "name": "allowHTTPS_all",
                        "properties": {
                            "description": "Allow HTTPS connections from all locations",
                            "protocol": "Tcp",
                            "sourcePortRange": "*",
                            "destinationPortRange": "443",
                            "sourceAddressPrefix": "*",
                            "destinationAddressPrefix": "*",
                            "access": "Allow",
                            "priority": 200,
                            "direction": "Inbound"
                        }
                    },
                    {
                        "name": "allowHTTPIn_all",
                        "properties": {
                            "description": "Allow HTTP connections from all locations",
                            "protocol": "Tcp",
                            "sourcePortRange": "*",
                            "destinationPortRange": "80",
                            "sourceAddressPrefix": "*",
                            "destinationAddressPrefix": "*",
                            "access": "Allow",
                            "priority": 300,
                            "direction": "Inbound"
                        }
                    }
                ]
            }
        },
        {
            "type": "Microsoft.Resources/deployments",
            "apiVersion": "2019-05-01",
            "name": "OpenShiftDeployment",
            "dependsOn": [
                "BastionVmDeployment"
            ],
            "properties": {
                "mode": "Incremental",
                "templateLink": {
                    "uri": "[variables('openshiftDeploymentTemplateUrl')]",
                    "contentVersion": "1.0.0.0"
                },
                "parameters": {
                    "_artifactsLocation": {
                        "value": "[uri(parameters('_artifactsLocation'), '.')]"
                    },
                    "_artifactsLocationSasToken": {
                        "value": "[parameters('_artifactsLocationSasToken')]"
                    },
                    "location": {
                        "value": "[parameters('location')]"
                    },
                    "openshiftDeploymentScriptUrl": {
                        "value": "[variables('openshiftDeploymentScriptUrl')]"
                    },
                    "openshiftDeploymentScriptFileName": {
                        "value": "[variables('openshiftDeploymentScriptFileName')]"
                    },
                    "masterInstanceCount": {
                        "value": "[parameters('masterInstanceCount')]"
                    },
                    "workerInstanceCount": {
                        "value": "[parameters('workerInstanceCount')]"
                    },
                    "adminUsername": {
                        "value": "[parameters('adminUsername')]"
                    },
                    "openshiftUsername": {
                        "value": "[parameters('openshiftUsername')]"
                    },
                    "openshiftPassword": {
                        "value": "[parameters('openshiftPassword')]"
                    },
                    "aadClientId": {
                        "value": "[parameters('aadClientId')]"
                    },
                    "aadClientSecret": {
                        "value": "[parameters('aadClientSecret')]"
                    },
                    "redHatTags": {
                        "value": "[variables('redHatTags')]"
                    },
                    "sshPublicKey": {
                        "value": "[parameters('sshPublicKey')]"
                    },
                    "pullSecret": {
                        "value": "[parameters('pullSecret')]"
                    },
                    "virtualNetworkName": {
                        "value": "[parameters('virtualNetworkName')]"
                    },
                    "virtualNetworkCIDR": {
                        "value": "[parameters('virtualNetworkCIDR')[0]]"
                    },
                    "storageOption": {
                        "value": "[parameters('storageOption')]"
                    },
                    "bastionHostname": {
                        "value": "[variables('bastionHostname')]"
                    },
                    "nfsIpAddress": {
                        "value": "[if(equals(parameters('storageOption'), 'nfs'),reference(resourceId('Microsoft.Network/networkInterfaces', concat(variables('nfsHostname'), '-nic'))).ipConfigurations[0].properties.privateIPAddress, '')]"
                    },
                    "singleZoneOrMultiZone": {
                        "value": "[parameters('singleZoneOrMultiZone')]"
                    },
                    "dnsZone": {
                        "value": "[parameters('dnsZone')]"
                    },
                    "dnsZoneRG": {
                        "value": "[parameters('dnsZoneRG')]"
                    },
                    "masterInstanceType": {
                        "value": "[parameters('masterVmSize')]"
                    },
                    "workerInstanceType": {
                        "value": "[parameters('workerVmSize')]"
                    },
                    "clusterName": {
                        "value": "[parameters('clusterName')]"
                    },
                    "networkResourceGroup": {
                        "value": "[variables('networkResourceGroup')]"
                    },
                    "masterSubnetName": {
                        "value": "[parameters('masterSubnetName')]"
                    },
                    "workerSubnetName": {
                        "value": "[parameters('workerSubnetName')]"
                    },
                    "enableFips": {
                        "value": "[parameters('enableFips')]"
                    },
                    "privateOrPublic": {
                        "value": "[if(equals(parameters('privateOrPublicEndpoints'), 'private'), 'Internal', 'External')]"
                    }
                }
            }
        },
        {
            "condition": "[equals(parameters('storageOption'), 'nfs')]",
            "type": "Microsoft.Resources/deployments",
            "apiVersion": "2019-05-01",
            "name": "nfsVmDeployment",
            "dependsOn": [
                "[resourceId('Microsoft.Network/networkInterfaces', concat(variables('nfsHostname'), '-nic'))]"
            ],
            "properties": {
                "mode": "Incremental",
                "templateLink": {
                    "uri": "[variables('clusterNodeDeploymentTemplateUrl')]",
                    "contentVersion": "1.0.0.0"
                },
                "parameters": {
                    "location": {
                        "value": "[parameters('location')]"
                    },
                    "sshKeyPath": {
                        "value": "[variables('sshKeyPath')]"
                    },
                    "sshPublicKey": {
                        "value": "[parameters('sshPublicKey')]"
                    },
                    "dataDiskSize": {
                        "value": "[parameters('dataDiskSize')]"
                    },
                    "adminUsername": {
                        "value": "[parameters('adminUsername')]"
                    },
                    "vmSize": {
                        "value": "[variables('nfsVmSize')]"
                    },
                    "hostname": {
                        "value": "[variables('nfsHostname')]"
                    },
                    "role": {
                        "value": "datanode"
                    },
                    "vmStorageType": {
                        "value": "Premium_LRS"
                    },
                    "imageReference": {
                        "value": "[variables('imageReference')]"
                    },
                    "redHatTags": {
                        "value": "[variables('redHatTags')]"
                    }
                }
            }
        },
        {
            "condition": "[equals(parameters('storageOption'), 'nfs')]",
            "type": "Microsoft.Compute/virtualMachines/extensions",
            "apiVersion": "2019-07-01",
            "name": "[concat(variables('nfsHostname'), '/installNfsServer')]",
            "location": "[parameters('location')]",
            "dependsOn": [
                "nfsVmDeployment"
            ],
            "tags": {
                "displayName": "InstallNfsServer",
                "app": "[variables('redHatTags').app]",
                "version": "[variables('redHatTags').version]",
                "platform": "[variables('redHatTags').platform]"
            },
            "properties": {
                "publisher": "Microsoft.Azure.Extensions",
                "type": "CustomScript",
                "typeHandlerVersion": "2.0",
                "autoUpgradeMinorVersion": true,
                "settings": {
                    "fileUris": [
                        "[variables('nfsInstallScriptUrl')]"
                    ]
                },
                "protectedSettings": {
                    "commandToExecute": "[concat('bash ', variables('nfsInstallScriptFileName'))]"
                }
            }
        },
        {
            "condition": "[equals(parameters('enableNfsBackup'), 'true')]",
            "type": "Microsoft.RecoveryServices/vaults",
            "apiVersion": "2019-05-13",
            "name": "[variables('vaultName')]",
            "location": "[parameters('location')]",
            "sku": {
                "name": "RS0",
                "tier": "Standard"
            },
            "properties": {}
        },
        {
            "condition": "[equals(parameters('enableNfsBackup'), 'true')]",
            "type": "Microsoft.RecoveryServices/vaults/backupFabrics/protectionContainers/protectedItems",
            "apiVersion": "2016-12-01",
            "name": "[concat(variables('vaultName'), '/', variables('backupFabric'), '/', variables('protectionContainer'), '/', variables('protectedItem'))]",
            "dependsOn": [
                "nfsVmDeployment",
                "[resourceId('Microsoft.RecoveryServices/vaults', variables('vaultName'))]"
            ],
            "properties": {
                "protectedItemType": "Microsoft.Compute/virtualMachines",
                "policyId": "[resourceId('Microsoft.RecoveryServices/vaults/backupPolicies', variables('vaultName'), variables('backupPolicyName'))]",
                "sourceResourceId": "[resourceId('Microsoft.Compute/virtualMachines', variables('nfsHostname'))]"
            }
        },
        {
            "type": "Microsoft.Compute/virtualMachines/extensions",
            "apiVersion": "2019-07-01",
            "name": "[concat(variables('bastionHostname'), '/deployOpenshift')]",
            "location": "[parameters('location')]",
            "dependsOn": [
                "BastionVmDeployment",
                "OpenShiftDeployment"
            ],
            "tags": {
                "displayName": "CloudPakConfig",
                "app": "[variables('redHatTags').app]",
                "version": "[variables('redHatTags').version]",
                "platform": "[variables('redHatTags').platform]"
            },
            "properties": {
                "publisher": "Microsoft.Azure.Extensions",
                "type": "CustomScript",
                "typeHandlerVersion": "2.0",
                "autoUpgradeMinorVersion": true,
                "settings": {
                    "fileUris": [
                        "[variables('cloudPakConfigScriptUrl')]"
                    ]
                },
                "protectedSettings": {
                    "commandToExecute": "[concat('bash ', variables('cloudPakConfigScriptFileName'), ' \"', uri(parameters('_artifactsLocation'), '.'), '\"', ' \"', parameters('_artifactsLocationSasToken'), '\"', ' \"', parameters('adminUsername'), '\"', ' \"', parameters('workerInstanceCount'), '\"', ' \"', parameters('projectName'), '\"', ' \"', parameters('apiKey'), '\"', ' \"', parameters('enableFips'), '\"')]"
                }
            }
        },
        {
            "condition": "[equals(parameters('cloudPakLicenseAgreement'), 'accept')]",
            "type": "Microsoft.Resources/deployments",
            "apiVersion": "2019-05-01",
            "name": "PreloadImagesLite",
            "dependsOn": [
                "nfsVmDeployment",
                "OpenShiftDeployment",
                "[variables('deployOpenshiftExt')]"
            ],
            "properties": {
                "mode": "Incremental",
                "templateLink": {
                    "uri": "[variables('preloadImagesDeploymentTemplateUrl')]",
                    "contentVersion": "1.0.0.0"
                },
                "parameters": {
                    "assembly": {
                        "value": "lite"
                    },
                    "uploadImagesScriptUrl": {
                        "value": "[variables('uploadImagesScriptUrl')]"
                    },
                    "uploadImagesScriptFileName": {
                        "value": "[variables('uploadImagesScriptFileName')]"
                    },
                    "redHatTags": {
                        "value": "[variables('redHatTags')]"
                    },
                    "adminUsername": {
                        "value": "[parameters('adminUsername')]"
                    },
                    "ocuser": {
                        "value": "[parameters('openshiftUsername')]"
                    },
                    "ocpassword": {
                        "value": "[parameters('openshiftPassword')]"
                    },
                    "bastionHostname": {
                        "value": "[variables('bastionHostname')]"
                    },
                    "projectName": {
                        "value": "[parameters('projectName')]"
                    },
                    "location": {
                        "value": "[parameters('location')]"
                    },
                    "clusterName": {
                        "value": "[parameters('clusterName')]"
                    },
                    "domainName": {
                        "value": "[parameters('dnsZone')]"
                    }
                }
            }
        },
        {
            "condition": "[equals(parameters('cloudPakLicenseAgreement'), 'accept')]",
            "type": "Microsoft.Resources/deployments",
            "apiVersion": "2019-05-01",
            "name": "CloudPakLiteDeployment",
            "dependsOn": [
                "nfsVmDeployment",
                "OpenShiftDeployment",
                "[variables('deployOpenshiftExt')]",
                "PreloadImagesLite"
            ],
            "properties": {
                "mode": "Incremental",
                "templateLink": {
                    "uri": "[variables('cloudPakDeploymentTemplateUrl')]",
                    "contentVersion": "1.0.0.0"
                },
                "parameters": {
                    "assembly": {
                        "value": "lite"
                    },
                    "cloudPakDeploymentScriptUrl": {
                        "value": "[variables('cloudPakDeploymentScriptUrl')]"
                    },
                    "cloudPakDeploymentScriptFileName": {
                        "value": "[variables('cloudPakDeploymentScriptFileName')]"
                    },
                    "redHatTags": {
                        "value": "[variables('redHatTags')]"
                    },
                    "adminUsername": {
                        "value": "[parameters('adminUsername')]"
                    },
                    "ocuser": {
                        "value": "[parameters('openshiftUsername')]"
                    },
                    "ocpassword": {
                        "value": "[parameters('openshiftPassword')]"
                    },
                    "storageOption": {
                        "value": "[parameters('storageOption')]"
                    },
                    "bastionHostname": {
                        "value": "[variables('bastionHostname')]"
                    },
                    "projectName": {
                        "value": "[parameters('projectName')]"
                    },
                    "location": {
                        "value": "[parameters('location')]"
                    },
                    "clusterName": {
                        "value": "[parameters('clusterName')]"
                    },
                    "domainName": {
                        "value": "[parameters('dnsZone')]"
                    }
                }
            }
        }
    ],
	"outputs": {
		"Openshift Console URL": {
			"type": "string",
			"value": "[concat('https://console-openshift-console.apps.', parameters('clusterName'), '.', parameters('dnsZone'))]"
		},
		"BastionVM SSH": {
			"type": "string",
			"value": "[concat('ssh ', parameters('adminUsername'), '@', reference(variables('bastionPublicIpDnsLabel')).dnsSettings.fqdn)]"
		},
		"Cloud Pak for Integration Platform Navigator URL": {
			"type": "string",
			"value": "[concat('https://', parameters('projectName'), '-icp4i-', parameters('projectName'), '.apps.',  parameters('clusterName'), '.', parameters('dnsZone'))]"
		}
	}
}
