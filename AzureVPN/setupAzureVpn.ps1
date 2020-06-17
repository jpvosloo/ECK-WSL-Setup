
#Install Powershell module
#https://docs.microsoft.com/en-us/powershell/azure/install-az-ps?view=azps-4.2.0&viewFallbackFrom=azps-3.3.0
if ($PSVersionTable.PSEdition -eq 'Desktop' -and (Get-Module -Name AzureRM -ListAvailable)) {
    Write-Error -Message ('Az module not installed. Having both the AzureRM and ' +
      'Az modules installed at the same time is not supported.');
      exit;
} else {
    Install-Module -Name Az -AllowClobber -Scope CurrentUser
}
pause

#Install local VPN client
https://cloud.ibm.com/docs/containers?topic=containers-vpn#vpn-setup
https://events19.linuxfoundation.org/wp-content/uploads/2017/11/Cross-Cloud-Connectivity-Migrating-and-Running-Your-Workload-in-Many-Clouds-Diego-Casati-Microsoft.pdf
https://geekdudes.wordpress.com/2019/01/30/creating-site-to-site-vpn-between-strongswan-and-amazon-aws-virtual-private-gateway/
#https://medium.com/ibm-cloud/setup-pop-to-pod-communication-across-ibm-cloud-private-clusters-add0b079ebf3
#https://www.ibm.com/cloud/blog/announcements/connecting-kubernetes-cluster-premises-resources
#https://azure.microsoft.com/en-us/blog/connecting-to-a-windows-azure-virtual-network-via-a-linux-based-software-vpn-device/
#https://wiki.strongswan.org/issues/2083


#Create VPN
#https://docs.microsoft.com/en-us/azure/vpn-gateway/vpn-gateway-tutorial-vpnconnection-powershell
#https://docs.microsoft.com/en-us/azure/vpn-gateway/scripts/vpn-gateway-sample-site-to-site-powershell
# Declare variables
  $VNetName  = "VNet1"
  $FESubName = "LifeStream"
  $GWSubName = "GatewaySubnet"
  $VNetPrefix1 = "10.0.0.0/16"
  $FESubPrefix = "10.1.0.0/24"
  $GWSubPrefix = "10.1.255.0/27"
  $VPNClientAddressPool = "192.168.0.0/24"
  $RG = "TestRG1"
  $Location = "East US"
  $GWName = "VNet1GW"
  $GWIPName = "VNet1GWIP"
  $GWIPconfName = "gwipconf"
# Create a resource group
New-AzResourceGroup -Name TestRG1 -Location EastUS
# Create a virtual network
$virtualNetwork = New-AzVirtualNetwork `
  -ResourceGroupName TestRG1 `
  -Location EastUS `
  -Name VNet1 `
  -AddressPrefix 10.1.0.0/16
# Create a subnet configuration
$subnetConfig = Add-AzVirtualNetworkSubnetConfig `
  -Name LifeStream `
  -AddressPrefix 10.1.0.0/24 `
  -VirtualNetwork $virtualNetwork
# Set the subnet configuration for the virtual network
$virtualNetwork | Set-AzVirtualNetwork
# Add a gateway subnet
$vnet = Get-AzVirtualNetwork -ResourceGroupName TestRG1 -Name VNet1
Add-AzVirtualNetworkSubnetConfig -Name 'GatewaySubnet' -AddressPrefix 10.1.255.0/27 -VirtualNetwork $vnet
# Set the subnet configuration for the virtual network
$vnet | Set-AzVirtualNetwork
# Request a public IP address
$gwpip= New-AzPublicIpAddress -Name VNet1GWIP -ResourceGroupName TestRG1 -Location 'East US' `
 -AllocationMethod Dynamic
# Create the gateway IP address configuration
$vnet = Get-AzVirtualNetwork -Name VNet1 -ResourceGroupName TestRG1
$subnet = Get-AzVirtualNetworkSubnetConfig -Name 'GatewaySubnet' -VirtualNetwork $vnet
$gwipconfig = New-AzVirtualNetworkGatewayIpConfig -Name gwipconfig1 -SubnetId $subnet.Id -PublicIpAddressId $gwpip.Id
# Create the VPN gateway
New-AzVirtualNetworkGateway -Name VNet1GW -ResourceGroupName TestRG1 `
 -Location 'East US' -IpConfigurations $gwipconfig -GatewayType Vpn `
 -VpnType RouteBased -GatewaySku VpnGw1
# Create the local network gateway
New-AzLocalNetworkGateway -Name Site1 -ResourceGroupName TestRG1 `
 -Location 'East US' -GatewayIpAddress '23.99.221.164' -AddressPrefix @('10.101.0.0/24','10.101.1.0/24')
# Configure your on-premises VPN device
# Create the VPN connection
$gateway1 = Get-AzVirtualNetworkGateway -Name VNet1GW -ResourceGroupName TestRG1
$local = Get-AzLocalNetworkGateway -Name Site1 -ResourceGroupName TestRG1
New-AzVirtualNetworkGatewayConnection -Name VNet1toSite1 -ResourceGroupName TestRG1 `
 -Location 'East US' -VirtualNetworkGateway1 $gateway1 -LocalNetworkGateway2 $local `
 -ConnectionType IPsec -RoutingWeight 10 -SharedKey 'abc123'
 
 
 