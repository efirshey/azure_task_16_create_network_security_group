$location = "uksouth"
$resourceGroupName = "mate-azure-task-16"

$virtualNetworkName = "todoapp"
$vnetAddressPrefix = "10.20.30.0/24"
$webSubnetName = "webservers"
$webSubnetIpRange = "10.20.30.0/26"
$dbSubnetName = "database"
$dbSubnetIpRange = "10.20.30.64/26"
$mngSubnetName = "management"
$mngSubnetIpRange = "10.20.30.128/26"

Write-Host "Creating a resource group $resourceGroupName ..."
New-AzResourceGroup -Name $resourceGroupName -Location $location

Write-Host "Creating web network security group..."
$webrule = New-AzNetworkSecurityRuleConfig -Name webservers-rule -Description "Allow HTTP and HTTPS traffic from the Internet" -Access Allow -Protocol Tcp -Direction Inbound -Priority 101 -SourceAddressPrefix Internet -SourcePortRange * -DestinationAddressPrefix * -DestinationPortRange 80,443
$webNSG = New-AzNetworkSecurityGroup -Name "$webSubnetName" -ResourceGroupName "$resourceGroupName" -Location "$location" -SecurityRules $webrule

Write-Host "Creating mngSubnet network security group..."
$mngrule = New-AzNetworkSecurityRuleConfig -Name mng-rule -Description "Allow SSH traffic from the Internet" -Access Allow -Protocol Tcp -Direction Inbound -Priority 102 -SourceAddressPrefix Internet -SourcePortRange * -DestinationAddressPrefix * -DestinationPortRange 22
$mngNSG = New-AzNetworkSecurityGroup -Name "$mngSubnetName" -ResourceGroupName "$resourceGroupName" -Location "$location" -SecurityRules $mngrule

Write-Host "Creating dbSubnet network security group..."
$dbrule = New-AzNetworkSecurityRuleConfig -Name db-rule -Description "Deny any traffic from the Internet" -Access Deny -Protocol * -Direction Inbound -Priority 100 -SourceAddressPrefix Internet -SourcePortRange * -DestinationAddressPrefix * -DestinationPortRange *
$dbNSG = New-AzNetworkSecurityGroup -Name "$dbSubnetName" -ResourceGroupName "$resourceGroupName" -Location "$location" -SecurityRules $dbrule

Write-Host "Creating a virtual network ..."
$webSubnet = New-AzVirtualNetworkSubnetConfig -Name $webSubnetName -AddressPrefix $webSubnetIpRange -NetworkSecurityGroup $webNSG
$dbSubnet = New-AzVirtualNetworkSubnetConfig -Name $dbSubnetName -AddressPrefix $dbSubnetIpRange -NetworkSecurityGroup $dbNSG
$mngSubnet = New-AzVirtualNetworkSubnetConfig -Name $mngSubnetName -AddressPrefix $mngSubnetIpRange -NetworkSecurityGroup $mngNSG
New-AzVirtualNetwork -Name $virtualNetworkName -ResourceGroupName $resourceGroupName -Location $location -AddressPrefix $vnetAddressPrefix -Subnet $webSubnet,$dbSubnet,$mngSubnet
