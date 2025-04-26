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

# Create Web NSG
Write-Host "Creating web network security group..."
$webrule = New-AzNetworkSecurityRuleConfig `
    -Name webservers-rule `
    -Description "Allow HTTP and HTTPS traffic from the Internet" `
    -Access Allow `
    -Protocol Tcp `
    -Direction Inbound `
    -Priority 101 `
    -SourceAddressPrefix Internet `
    -SourcePortRange * `
    -DestinationAddressPrefix * `
    -DestinationPortRange 80,443

$webNSG = New-AzNetworkSecurityGroup `
    -Name "$webSubnetName" `
    -ResourceGroupName "$resourceGroupName" `
    -Location "$location" `
    -SecurityRules $webrule

# Create Management NSG
Write-Host "Creating mngSubnet network security group..."
$mngrule = New-AzNetworkSecurityRuleConfig `
    -Name mng-rule `
    -Description "Allow SSH traffic from the Internet" `
    -Access Allow `
    -Protocol Tcp `
    -Direction Inbound `
    -Priority 102 `
    -SourceAddressPrefix Internet `
    -SourcePortRange * `
    -DestinationAddressPrefix * `
    -DestinationPortRange 22

$mngNSG = New-AzNetworkSecurityGroup `
    -Name "$mngSubnetName" `
    -ResourceGroupName "$resourceGroupName" `
    -Location "$location" `
    -SecurityRules $mngrule

# Create Database NSG (FIXED PART)
Write-Host "Creating dbSubnet network security group..."

# Rule 1: Deny traffic from Internet
$dbrule_deny_internet = New-AzNetworkSecurityRuleConfig `
    -Name db-deny-internet `
    -Description "Deny any traffic from the Internet" `
    -Access Deny `
    -Protocol * `
    -Direction Inbound `
    -Priority 100 `
    -SourceAddressPrefix Internet `
    -SourcePortRange * `
    -DestinationAddressPrefix * `
    -DestinationPortRange *

# Rule 2: Allow traffic from Web Subnet
$dbrule_allow_web = New-AzNetworkSecurityRuleConfig `
    -Name db-allow-web-subnet `
    -Description "Allow inbound traffic from web subnet" `
    -Access Allow `
    -Protocol * `
    -Direction Inbound `
    -Priority 110 `
    -SourceAddressPrefix $webSubnetIpRange `
    -SourcePortRange * `
    -DestinationAddressPrefix * `
    -DestinationPortRange *

# Attach both rules to db NSG
$dbNSG = New-AzNetworkSecurityGroup `
    -Name "$dbSubnetName" `
    -ResourceGroupName "$resourceGroupName" `
    -Location "$location" `
    -SecurityRules $dbrule_deny_internet, $dbrule_allow_web

# Create the virtual network and subnets
Write-Host "Creating a virtual network ..."
$webSubnet = New-AzVirtualNetworkSubnetConfig `
    -Name $webSubnetName `
    -AddressPrefix $webSubnetIpRange `
    -NetworkSecurityGroup $webNSG

$dbSubnet = New-AzVirtualNetworkSubnetConfig `
    -Name $dbSubnetName `
    -AddressPrefix $dbSubnetIpRange `
    -NetworkSecurityGroup $dbNSG

$mngSubnet = New-AzVirtualNetworkSubnetConfig `
    -Name $mngSubnetName `
    -AddressPrefix $mngSubnetIpRange `
    -NetworkSecurityGroup $mngNSG

New-AzVirtualNetwork `
    -Name $virtualNetworkName `
    -ResourceGroupName $resourceGroupName `
    -Location $location `
    -AddressPrefix $vnetAddressPrefix `
    -Subnet $webSubnet, $dbSubnet, $mngSubnet
