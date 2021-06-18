{
    "$schema": "https://schema.management.azure.com/schemas/2019-04-01/deploymentTemplate.json#",
    "contentVersion": "1.0.0.0",
    "parameters": {
        "_artifactsLocation": {
            "defaultValue": "https://raw.githubusercontent.com/amiivas/cloud-pak-for-integration/main/",
            "type": "String",
            "metadata": {
                "description": "The base URL where artifacts required by this template are located. When the template is deployed using the accompanying scripts, a private location in the subscription will be used and this value will be automatically generated."
            }
        },
        "_artifactsLocationSasToken": {
            "defaultValue": "",
            "type": "SecureString",
            "metadata": {
                "description": "Token for the base URL where artifacts required by this template are located. When the template is deployed using the accompanying scripts, a private location in the subscription will be used and this value will be automatically generated."
            }
        },
        "location": {
            "defaultValue": "[resourceGroup().location]",
            "type": "String",
            "metadata": {
                "description": "Region where the resources should be created in"
            }
        },
        "aadClientId": {
            "type": "String",
            "metadata": {
                "description": "Azure AD Client ID"
            }
        },
        "aadClientSecret": {
            "type": "SecureString",
            "metadata": {
                "description": "Azure AD Client Secret"
            }
        },
        "adminUsername": {
            "minLength": 4,
            "type": "String",
            "metadata": {
                "description": "Administrator username on Bastion VM"
            }
        },
        "bastionVmSize": {
            "type": "String",
            "metadata": {
                "description": "Bastion Host VM size. Use VMs with Premium Storage support only."
            }
        },
        "sshPublicKey": {
            "type": "String",
            "metadata": {
                "description": "SSH public key for all VMs"
            }
        },
        "openshiftVersion": {
            "allowedValues": [
                "4.7.15",
                "4.6.33"
            ],
            "type": "String",
            "metadata": {
                "description": "Openshift version"
            }
        },
        "masterInstanceCount": {
            "allowedValues": [
                3,
                5
            ],
            "type": "Int",
            "metadata": {
                "description": "Number of OpenShift masters."
            }
        },
        "workerInstanceCount": {
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
            "type": "Int",
            "metadata": {
                "description": "Number of OpenShift nodes"
            }
        },
        "masterVmSize": {
            "type": "String",
            "metadata": {
                "description": "OpenShift Master VM size. Use VMs with Premium Storage support only."
            }
        },
        "workerVmSize": {
            "type": "String",
            "metadata": {
                "description": "OpenShift Node VM(s) size. Use VMs with Premium Storage support only."
            }
        },
        "newOrExistingNetwork": {
            "allowedValues": [
                "new",
                "existing"
            ],
            "type": "String",
            "metadata": {
                "description": "Deploy in new cluster or in existing cluster. If existing cluster, make sure the new resources are in the same zone"
            }
        },
        "existingVnetResourceGroupName": {
            "defaultValue": "[resourceGroup().name]",
            "type": "String",
            "metadata": {
                "description": "Resource Group for Existing Vnet."
            }
        },
        "virtualNetworkName": {
            "type": "String",
            "metadata": {
                "description": "Name of new or existing virtual network"
            }
        },
        "virtualNetworkCIDR": {
            "type": "Array",
            "metadata": {
                "description": "VNet Address Prefix. Minimum address prefix is /24"
            }
        },
        "masterSubnetName": {
            "type": "String",
            "metadata": {
                "description": "Name of new or existing master subnet"
            }
        },
        "masterSubnetPrefix": {
            "type": "String",
            "metadata": {
                "description": "Master subnet address prefix"
            }
        },
        "workerSubnetName": {
            "type": "String",
            "metadata": {
                "description": "Name of new or existing worker subnet"
            }
        },
        "workerSubnetPrefix": {
            "type": "String",
            "metadata": {
                "description": "Worker subnet address prefix"
            }
        },
        "bastionSubnetName": {
            "type": "String",
            "metadata": {
                "description": "Name of new or existing bastion subnet"
            }
        },
        "bastionSubnetPrefix": {
            "type": "String",
            "metadata": {
                "description": "Worker subnet address prefix"
            }
        },
        "singleZoneOrMultiZone": {
            "allowedValues": [
                "az",
                "noha"
            ],
            "type": "String",
            "metadata": {
                "description": "Deploy to a Single AZ or multiple AZs"
            }
        },
        "dnsZone": {
            "type": "String",
            "metadata": {
                "description": "Domain name created with the App Service"
            }
        },
        "dnsZoneRG": {
            "type": "String",
            "metadata": {
                "description": "Resource Group that contains the domain name"
            }
        },
        "installOpenshift": {
            "allowedValues": [
                "yes",
                "no"
            ],
            "type": "String",
            "metadata": {
                "description": "To check if new openshift cluster need to be install"
            }
        },
        "pullSecret": {
            "minLength": 1,
            "type": "SecureString",
            "metadata": {
                "description": "Openshift PullSecret JSON Blob"
            }
        },
        "clusterName": {
            "type": "String",
            "metadata": {
                "description": "Cluster resources prefix"
            }
        },
        "openshiftUsername": {
            "type": "String",
            "metadata": {
                "description": "OpenShift login username"
            }
        },
        "openshiftPassword": {
            "minLength": 8,
            "type": "SecureString",
            "metadata": {
                "description": "OpenShift login password"
            }
        },
        "enableFips": {
            "type": "Bool",
            "metadata": {
                "description": "Enable FIPS encryption"
            }
        },
        "storageOption": {
            "allowedValues": [
                "portworx",
                "nfs",
                "none"
            ],
            "type": "String"
        },
        "enableNfsBackup": {
            "allowedValues": [
                true,
                false
            ],
            "type": "Bool",
            "metadata": {
                "description": "Enable Backup on NFS node"
            }
        },
        "dataDiskSize": {
            "allowedValues": [
                512,
                1024,
                2048
            ],
            "type": "Int",
            "metadata": {
                "description": "Size of Datadisk in GB for NFS storage"
            }
        },
        "privateOrPublicEndpoints": {
            "allowedValues": [
                "public",
                "private"
            ],
            "type": "String",
            "metadata": {
                "description": "Public or private facing endpoints"
            }
        },
        "projectName": {
            "type": "String",
            "metadata": {
                "description": "Openshift Namespace to deploy project"
            }
        },
        "apiKey": {
            "type": "SecureString",
            "metadata": {
                "description": "IBM Container Registry API Key. See README on how to obtain this"
            }
        },
        "storageAccountName": {
            "type": "String",
            "metadata": {
                "description": "Give a unique name for storage account"
            }
        },
        "accountType": {
            "type": "String",
            "metadata": {
                "description": "Storage Account type"
            }
        },
        "cloudPakLicenseAgreement": {
            "allowedValues": [
                "accept",
                "reject"
            ],
            "type": "String",
            "metadata": {
                "description": "Accept License Agreement: https://ibm.biz/Bdq6KP"
            }
        },
        "cloudPakVersion": {
            "allowedValues": [
                "2021.1.1",
                "2020.4.1",
                "2020.3.1"
            ],
            "type": "String",
            "metadata": {
                "description": "Cloud Pak of Integration version"
            }
        },
        "platformNavigatorReplicas": {
            "allowedValues": [
                1,
                2,
                3,
                4,
                5,
                6,
                7,
                8,
                9,
                10
            ],
            "type": "Int",
            "metadata": {
                "description": "Number of IBM Platform Navigator Replicas"
            }
        },
        "capabilityAPIConnect": {
            "allowedValues": [
                true,
                false
            ],
            "type": "Bool",
            "metadata": {
                "description": "Deploy IBM API Connect Capability"
            }
        },
        "capabilityAPPConnectDashboard": {
            "allowedValues": [
                true,
                false
            ],
            "type": "Bool",
            "metadata": {
                "description": "Deploy IBM App Connect Dashboard Capability"
            }
        },
        "capabilityAPPConenctDesigner": {
            "allowedValues": [
                true,
                false
            ],
            "type": "Bool",
            "metadata": {
                "description": "Deploy IBM App Connect Designer Capability"
            }
        },
        "capabilityAssetRepository": {
            "allowedValues": [
                true,
                false
            ],
            "type": "Bool",
            "metadata": {
                "description": "Deploy IBM Asset Repository Capability"
            }
        },
        "capabilityOperationsDashboard": {
            "allowedValues": [
                true,
                false
            ],
            "type": "Bool",
            "metadata": {
                "description": "Deploy IBM Operations Dashboard Capability"
            }
        },
        "runtimeMQ": {
            "allowedValues": [
                true,
                false
            ],
            "type": "Bool",
            "metadata": {
                "description": "Deploy IBM MQ Runtime"
            }
        },
        "runtimeKafka": {
            "allowedValues": [
                true,
                false
            ],
            "type": "Bool",
            "metadata": {
                "description": "Deploy Confluent Kafka Runtime"
            }
        },
        "runtimeAspera": {
            "allowedValues": [
                true,
                false
            ],
            "type": "Bool",
            "metadata": {
                "description": "Deploy IBM Aspera Runtime"
            }
        },
        "runtimeDataPower": {
            "allowedValues": [
                true,
                false
            ],
            "type": "Bool",
            "metadata": {
                "description": "Deploy IBM DataPower Runtime"
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
        "bastionPublicIpDnsLabel": "[concat('bastiondns', uniqueString(resourceGroup().id))]",
        "sshKeyPath": "[concat('/home/', parameters('adminUsername'), '/.ssh/authorized_keys')]",
        "clusterNodeDeploymentTemplateUrl": "[uri(parameters('_artifactsLocation'), concat('nested/clusternode.json', parameters('_artifactsLocationSasToken')))]",
        "openshiftDeploymentTemplateUrl": "[uri(parameters('_artifactsLocation'), concat('nested/openshiftdeploy.json', parameters('_artifactsLocationSasToken')))]",
        "openshiftDeploymentScriptUrl": "[uri(parameters('_artifactsLocation'), concat('scripts/deployOpenShiftv1.sh', parameters('_artifactsLocationSasToken')))]",
        "cloudPakDeploymentTemplateUrl": "[uri(parameters('_artifactsLocation'), concat('nested/cloudpakdeploy.json', parameters('_artifactsLocationSasToken')))]",
        "cloudPakDeploymentScriptUrl": "[uri(parameters('_artifactsLocation'), concat('scripts/deployCloudPakv14.sh', parameters('_artifactsLocationSasToken')))]",
        "cloudPakConfigScriptFileName": "openshiftCloudPakConfig.sh",
        "cloudPakConfigScriptUrl": "[uri(parameters('_artifactsLocation'), concat('scripts/openshiftCloudPakConfig.sh', parameters('_artifactsLocationSasToken')))]",
        "nfsInstallScriptUrl": "[uri(parameters('_artifactsLocation'), concat('scripts/setup-nfs.sh', parameters('_artifactsLocationSasToken')))]",
        "productInstallationScriptPath": "[uri(parameters('_artifactsLocation'), concat('scripts/product_scripts', parameters('_artifactsLocationSasToken')))]",
        "openshiftDeploymentScriptFileName": "deployOpenShiftv1.sh",
        "cloudPakDeploymentScriptFileName": "deployCloudPakv14.sh",
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
            "type": "Microsoft.Network/virtualNetworks",
            "apiVersion": "2019-09-01",
            "name": "[parameters('virtualNetworkName')]",
            "location": "[parameters('location')]",
            "dependsOn": [
                "[variables('bastionSecurityGroupName')]",
                "[variables('masterSecurityGroupName')]",
                "[variables('workerSecurityGroupName')]"
            ],
            "tags": {
                "displayName": "VirtualNetwork",
                "app": "[variables('redHatTags').app]",
                "version": "[parameters('openshiftVersion')]",
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
            "condition": "[equals(parameters('newOrExistingNetwork'), 'new')]"
        },
        {
            "type": "Microsoft.Network/publicIPAddresses",
            "apiVersion": "2019-09-01",
            "name": "[variables('bastionPublicIpDnsLabel')]",
            "location": "[parameters('location')]",
            "tags": {
                "displayName": "BastionPublicIP",
                "app": "[variables('redHatTags').app]",
                "version": "[parameters('openshiftVersion')]",
                "platform": "[variables('redHatTags').platform]"
            },
            "sku": {
                "name": "Standard"
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
                "version": "[parameters('openshiftVersion')]",
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
                "version": "[parameters('openshiftVersion')]",
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
            },
            "condition": "[equals(parameters('storageOption'), 'nfs')]"
        },
        {
            "type": "Microsoft.Network/networkSecurityGroups",
            "apiVersion": "2019-09-01",
            "name": "[variables('bastionSecurityGroupName')]",
            "location": "[parameters('location')]",
            "tags": {
                "displayName": "BastionNSG",
                "app": "[variables('redHatTags').app]",
                "version": "[parameters('openshiftVersion')]",
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
                "version": "[parameters('openshiftVersion')]",
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
                "version": "[parameters('openshiftVersion')]",
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
                    },
					"openshiftVersion": {
                        "value": "[parameters('openshiftVersion')]"
                    }
                }
            },
            "condition": "[equals(parameters('installOpenshift'), 'yes')]"
        },
        {
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
            },
            "condition": "[equals(parameters('storageOption'), 'nfs')]"
        },
        {
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
                "version": "[parameters('openshiftVersion')]",
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
            },
            "condition": "[equals(parameters('storageOption'), 'nfs')]"
        },
        {
            "type": "Microsoft.RecoveryServices/vaults",
            "apiVersion": "2020-10-01",
            "name": "[variables('vaultName')]",
            "location": "[parameters('location')]",
            "sku": {
                "name": "RS0",
                "tier": "Standard"
            },
            "properties": {},
            "condition": "[equals(parameters('enableNfsBackup'), 'true')]"
        },
        {
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
            },
            "condition": "[equals(parameters('enableNfsBackup'), 'true')]"
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
                "version": "[parameters('openshiftVersion')]",
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
            },
            "condition": "[equals(parameters('installOpenshift'), 'yes')]"
        },
        {
            "type": "Microsoft.Storage/storageAccounts",
            "apiVersion": "2019-06-01",
            "name": "[parameters('storageAccountName')]",
            "location": "[parameters('location')]",
            "dependsOn": [],
            "tags": {
                "env": "dev"
            },
            "sku": {
                "name": "[parameters('accountType')]"
            },
            "kind": "StorageV2",
            "properties": {
                "accessTier": "Hot",
                "minimumTlsVersion": "TLS1_2",
                "supportsHttpsTrafficOnly": true,
                "allowBlobPublicAccess": true,
                "allowSharedKeyAccess": true,
                "networkAcls": {
                    "bypass": "AzureServices",
                    "defaultAction": "Allow",
                    "ipRules": []
                }
            },
            "condition": "[parameters('capabilityAssetRepository')]"
        },
        {
            "type": "Microsoft.Resources/deployments",
            "apiVersion": "2019-05-01",
            "name": "CloudPakLiteDeployment",
            "dependsOn": [
                "nfsVmDeployment",
                "OpenShiftDeployment",
                "[variables('deployOpenshiftExt')]",
                "[resourceId('Microsoft.Storage/storageAccounts/', parameters('storageAccountName'))]"
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
                    "productInstallationScriptPath": {
                        "value": "[variables('productInstallationScriptPath')]"
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
                    },
                    "apiKey": {
                        "value": "[parameters('apiKey')]"
                    },
					 "cloudPakVersion": {
                        "value": "[parameters('cloudPakVersion')]"
                    },
                    "platformNavigatorReplicas": {
                        "value": "[parameters('platformNavigatorReplicas')]"
                    },
                    "capabilityAPIConnect": {
                        "value": "[parameters('capabilityAPIConnect')]"
                    },
                    "capabilityAPPConnectDashboard": {
                        "value": "[parameters('capabilityAPPConnectDashboard')]"
                    },
                    "capabilityAPPConenctDesigner": {
                        "value": "[parameters('capabilityAPPConenctDesigner')]"
                    },
                    "capabilityAssetRepository": {
                        "value": "[parameters('capabilityAssetRepository')]"
                    },
                    "capabilityOperationsDashboard": {
                        "value": "[parameters('capabilityOperationsDashboard')]"
                    },
                    "runtimeMQ": {
                        "value": "[parameters('runtimeMQ')]"
                    },
                    "runtimeKafka": {
                        "value": "[parameters('runtimeKafka')]"
                    },
                    "runtimeAspera": {
                        "value": "[parameters('runtimeAspera')]"
                    },
                    "runtimeDataPower": {
                        "value": "[parameters('runtimeDataPower')]"
                    },
                    "storageAccountName": {
                        "value": "[parameters('storageAccountName')]"
                    }
                }
            },
            "condition": "[equals(parameters('cloudPakLicenseAgreement'), 'accept')]"
        }
    ],
    "outputs": {
        "Openshift Console URL": {
            "type": "String",
            "value": "[concat('https://console-openshift-console.apps.', parameters('clusterName'), '.', parameters('dnsZone'))]"
        },
        "BastionVM SSH": {
            "type": "String",
            "value": "[concat('ssh ', parameters('adminUsername'), '@', reference(variables('bastionPublicIpDnsLabel')).dnsSettings.fqdn)]"
        },
        "Cloud Pak for Integration Platform Navigator URL": {
            "type": "String",
            "value": "[concat('https://', parameters('projectName'), '-navigator-pn-', parameters('projectName'), '.apps.',  parameters('clusterName'), '.', parameters('dnsZone'))]"
        },
        "MQ Web Console": {
            "type": "String",
            "value": "[concat('https://icp-mq-ibm-mq-web-', parameters('projectName'), '.apps.',  parameters('clusterName'), '.', parameters('dnsZone'), '/ibmmq/console')]"
        },
        "Kafka Web Console": {
            "type": "String",
            "value": "[concat('https://kafka-dev-ibm-es-ui-', parameters('projectName'), '.apps.',  parameters('clusterName'), '.', parameters('dnsZone'), '/ibmmq/console')]"
        },
        "API Connect - Cloud Manager Console": {
            "type": "String",
            "value": "[concat('https://apic-mgmt-admin-', parameters('projectName'), '.apps.',  parameters('clusterName'), '.', parameters('dnsZone'), '/admin')]"
        },
        "API Connect - API Manager": {
            "type": "String",
            "value": "[concat('https://apic-mgmt-api-manager-', parameters('projectName'), '.apps.',  parameters('clusterName'), '.', parameters('dnsZone'), '/manager')]"
        },
        "Demo API": {
            "type": "String",
            "value": "[concat('https://apic-gw-gateway-', parameters('projectName'), '.apps.',  parameters('clusterName'), '.', parameters('dnsZone'), '/cts-demo/sandbox/v1/demo')]"
        },
        "Asset Repo Web Console": {
            "type": "String",
            "value": "[concat('https://assetrepo-dev-ibm-ar-,', parameters('projectName'), '.apps.',  parameters('clusterName'), '.', parameters('dnsZone'))]"
        }
    }
}
