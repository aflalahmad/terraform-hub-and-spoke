<!-- BEGIN_TF_DOCS -->
# Hub Resource Group 🌐

## Centralized Services and Networking Overview 🌐
- The Hub Resource Group contains resources that provide centralized services and networking for the entire infrastructure, acting as a central point for connectivity and security management.

## Prerequisites ⚙️
### Before running this Terraform configuration, ensure you have the following prerequisites:

- Terraform installed on your local machine. 🛠️
- Azure CLI installed and authenticated. 🔑
- Proper access permissions to create resources in the Azure subscription. ✅
### Configuration Details 📝
### Integration and Communication Between Spokes 🔗
1. Create the Resource Group 🗂️
- Set up a resource group for the hub to house all centralized services and networking resources.

2. Create the Virtual Network 🌐
- Define a virtual network for the hub, specifying the address space and other configurations.

3. Create Subnets 🧩
- Segment the virtual network into smaller subnets, each with its own address prefix and potential service delegations.

4. Create Public IPs 🌍
- Allocate public IP addresses for resources that need to be accessible from the internet.

5. Create a Bastion Host 🔐
- Deploy a Bastion Host for secure RDP/SSH access to virtual machines in the network without exposing them to the public internet.

6. Create a Virtual Network Gateway 🔗
- Establish a VPN gateway to enable site-to-site VPN connections between on-premises and Azure.

7. Create a Firewall 🛡️
- Deploy a firewall to protect and control inbound and outbound traffic across the network.

8. Create a Firewall Policy 📜
- Define a firewall policy to manage rules and settings for the Azure Firewall.

9. Create an IP Group 🏷️
- Organize IP addresses into groups for easier management and application of firewall rules.

10. Create Firewall Rules 🔧
- Configure network and application rules within the firewall policy to control traffic flow.

11. Set Up Virtual Network Peering 🔄
- Establish peering connections between the hub virtual network and the spoke virtual networks to enable communication between them.

### Integration with On-Premises Network 🏢
1. Define On-Premises Public IP and Virtual Network 🌍
- Obtain the public IP address and define the virtual network for the on-premises infrastructure.

2. Create a Local Network Gateway 🌐
- Set up a local network gateway in Azure to represent the on-premises VPN device. Specify the public IP address of the on-premises VPN device and the address space used in the on-premises network.

3. Create a VPN Connection 🔗
- Establish a VPN connection between the Azure virtual network gateway and the on-premises local network gateway. Configure the connection type (IPsec) and the shared key for authentication.

4. Create a Route Table 🗺️
- Define a route table to manage traffic routing between the on-premises network and Azure. Add routes to ensure traffic destined for the on-premises network is correctly directed through the VPN gateway.

5. Associate the Route Table with Subnets 🔗
- Link the route table to the appropriate subnets within the hub virtual network to enforce the routing rules.

# Diagram
![hub](https://github.com/user-attachments/assets/2399f67a-33f2-445f-b4fe-e84960523e5e)

### Apply the Terraform configurations :
Deploy the resources using Terraform,
- Initialize Terraform 🔄:
```
terraform init
```
- Plan the Deployment 📝:

```
terraform plan
```
- Apply the Configuration ✅:
```
terraform apply
```

```hcl
#Create a resource group
resource "azurerm_resource_group" "rg" {
    name = var.rg.resource_group
    location = var.rg.location
}

#virtual network

resource "azurerm_virtual_network" "hubvnets" {

    name  = var.vnet_name
    address_space = [var.address_space]
    resource_group_name =azurerm_resource_group.rg.name
    location = azurerm_resource_group.rg.location
    
   
    depends_on = [ azurerm_resource_group.rg ]
}

#subnet for all
resource "azurerm_subnet" "subnet" {
    for_each = var.subnet_details
    name = each.value.subnet_name
    address_prefixes = [each.value.address_prefixes]
    resource_group_name = azurerm_resource_group.rg.name
    virtual_network_name = azurerm_virtual_network.hubvnets.name
  
    depends_on = [ azurerm_virtual_network.hubvnets]
   
  dynamic "delegation" {
    for_each = each.value.delegations
    content {
      name = delegation.value.name
      service_delegation {
        name    = delegation.value.service_delegation
        actions = delegation.value.actions
      }
    }
  }
}
  
#publiips for all
resource "azurerm_public_ip" "publi_ips" {
  for_each = var.publicip_names
  name                = each.value.name
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  allocation_method   = "Static"  
  sku                 = "Standard"

  tags = {
    environment = "Example"
  }
}

#bastion host
resource "azurerm_bastion_host" "example" {
  name                = var.bastionhost_name
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  ip_configuration {
    name = "ipconfig"
    public_ip_address_id = azurerm_public_ip.publi_ips["bastion-pip"].id
    subnet_id = azurerm_subnet.subnet["AzureBastionSubnet"].id 
  }
 depends_on = [ azurerm_subnet.subnet["AzureBastionSubnet"] ]
}

#virtual network gateway
resource "azurerm_virtual_network_gateway" "vnetgateway" {

    name = var.virtual_network_gateway_name
    resource_group_name = azurerm_resource_group.rg.name
    location = azurerm_resource_group.rg.location
    type = "Vpn"
    vpn_type = "RouteBased"
    sku = "VpnGw1"

    ip_configuration {
      name = "vnetgatewayconfiguration"
      public_ip_address_id = azurerm_public_ip.publi_ips["gateway-public-ip"].id
      private_ip_address_allocation = "Dynamic"
      subnet_id = azurerm_subnet.subnet["GatewaySubnet"].id 
    }
    depends_on = [ azurerm_subnet.subnet["GatewaySubnet"] ]
  
}


#firewall
resource "azurerm_firewall" "firewall" {

  name                = var.firewall_name
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  sku_name = "AZFW_VNet"
  sku_tier = "Standard" 


  ip_configuration {
    name                 = "configuration"
    subnet_id            = azurerm_subnet.subnet["AzureFirewallSubnet"].id
    public_ip_address_id = azurerm_public_ip.publi_ips["firewall-pip"].id
  }
   firewall_policy_id = azurerm_firewall_policy.policy.id
   depends_on = [azurerm_subnet.subnet["AzureFirewallSubnet"]]
}

#firewall policy
resource "azurerm_firewall_policy" "policy" {
  name                = var.firewall_policy_name
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
 sku = "Standard"
  base_policy_id      = null
  
}

#firewall rule
resource "azurerm_firewall_policy_rule_collection_group" "icmp_rule" {

  name = "firewall-network-rule"
  firewall_policy_id = azurerm_firewall_policy.policy.id
  priority = 100

  nat_rule_collection {          
    name     = "DNat-rule-collection"
    priority = 100
    action   = "Dnat"

    rule {
      name             = "Allow-RDP"
      source_addresses = ["103.25.44.14"]   
      destination_ports = ["3389"]
      destination_address = azurerm_public_ip.publi_ips["firewall-pip"].ip_address
      translated_address = "10.100.2.4"   
      translated_port    = "3389"
      protocols         = ["TCP"]
    }
  }
 
 network_rule_collection {
    name     = "AllowICMP_Rules"
    priority = 200
     action       = "Allow"

    rule {
      name         = "AllowICMP"
      protocols = ["Any"]
      destination_ports = ["*"]
      source_addresses = ["10.20.0.0/16"]  
      destination_addresses = ["10.30.0.0/16"]
    }
  }
}

#connect to on premise 
 data "azurerm_public_ip" "onprem_publicip" {
   name = "onprem_vnetgatway_publicip"
   resource_group_name = "onprem_RG"
 }

data "azurerm_virtual_network" "onprem_vnet" {
  name = "onpremVNet"
  resource_group_name = "onprem_RG"
}

#local network gateway
resource "azurerm_local_network_gateway" "hub_local_network_gateway" {
    name = var.hub_local_network_gateway_name
    location = azurerm_resource_group.rg.location
    resource_group_name = azurerm_resource_group.rg.name
    gateway_address = data.azurerm_public_ip.onprem_publicip.ip_address
    address_space = [data.azurerm_virtual_network.onprem_vnet.address_space[0]]
    depends_on = [ azurerm_public_ip.publi_ips,azurerm_virtual_network_gateway.vnetgateway,
     data.azurerm_public_ip.onprem_publicip,data.azurerm_virtual_network.onprem_vnet]
}

#gateway connection
resource "azurerm_virtual_network_gateway_connection" "onprem_vpn_connection" {
     name = var.vnet_gateway_connection
     location = azurerm_resource_group.rg.location
     resource_group_name = azurerm_resource_group.rg.name
     virtual_network_gateway_id = azurerm_virtual_network_gateway.vnetgateway.id
     local_network_gateway_id = azurerm_local_network_gateway.hub_local_network_gateway.id
     type = "IPsec"
     connection_protocol = "IKEv2"
     shared_key = "YourSharedKey"

     depends_on = [ azurerm_virtual_network_gateway.vnetgateway,azurerm_local_network_gateway.hub_local_network_gateway ]
}

#create the route table

resource "azurerm_route_table" "route_table" {
  name = "Hub-route-table"
  resource_group_name = azurerm_resource_group.rg.name
  location = azurerm_resource_group.rg.location
  depends_on = [ azurerm_resource_group.rg,azurerm_subnet.subnet ]
  route {
  name = "To-spoke1"
  next_hop_type = "VirtualAppliance"
  address_prefix = "10.30.0.0/16"
  next_hop_in_ip_address = "10.10.3.4"
}
}
resource "azurerm_subnet_route_table_association" "route-table-ass" {
   subnet_id                 = azurerm_subnet.subnet["GatewaySubnet"].id
  route_table_id = azurerm_route_table.route_table.id
  depends_on = [ azurerm_subnet.subnet , azurerm_route_table.route_table ]
}

/*
resource "azurerm_monitor_diagnostic_setting" "diagnostic_setting" {
  for_each = {
    "firewall" = azurerm_firewall.firewall.id
    "vnet_gateway" = azurerm_virtual_network_gateway.vnet_gateway.id
  }

  name                         = "${each.key}-diagnostic-setting"
  target_resource_id           = each.value
  log_analytics_workspace_id   = azurerm_log_analytics_workspace.log_analytics_workspace.id

  log {
    category = "AllLogs"
    enabled  = true
    retention_policy {
      enabled = true
      days    = 30
    }
  }

  metric {
    category = "AllMetrics"
    enabled  = true
    retention_policy {
      enabled = true
      days    = 30
    }
  }
}

resource "azurerm_log_analytics_workspace" "log_analytics_workspace" {
  name                = "logAnalyticsWorkspace"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  sku                 = "PerGB2018"
  retention_in_days   = 30
}
*/
```

<!-- markdownlint-disable MD033 -->
## Requirements

The following requirements are needed by this module:

- <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) (>= 1.1.0)

- <a name="requirement_azurerm"></a> [azurerm](#requirement\_azurerm) (~> 3.1.0)

## Providers

The following providers are used by this module:

- <a name="provider_azurerm"></a> [azurerm](#provider\_azurerm) (~> 3.1.0)

## Resources

The following resources are used by this module:

- [azurerm_bastion_host.example](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/bastion_host) (resource)
- [azurerm_firewall.firewall](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/firewall) (resource)
- [azurerm_firewall_policy.policy](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/firewall_policy) (resource)
- [azurerm_firewall_policy_rule_collection_group.icmp_rule](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/firewall_policy_rule_collection_group) (resource)
- [azurerm_local_network_gateway.hub_local_network_gateway](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/local_network_gateway) (resource)
- [azurerm_public_ip.publi_ips](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/public_ip) (resource)
- [azurerm_resource_group.rg](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/resource_group) (resource)
- [azurerm_route_table.route_table](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/route_table) (resource)
- [azurerm_subnet.subnet](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/subnet) (resource)
- [azurerm_subnet_route_table_association.route-table-ass](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/subnet_route_table_association) (resource)
- [azurerm_virtual_network.hubvnets](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/virtual_network) (resource)
- [azurerm_virtual_network_gateway.vnetgateway](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/virtual_network_gateway) (resource)
- [azurerm_virtual_network_gateway_connection.onprem_vpn_connection](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/virtual_network_gateway_connection) (resource)
- [azurerm_public_ip.onprem_publicip](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/data-sources/public_ip) (data source)
- [azurerm_virtual_network.onprem_vnet](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/data-sources/virtual_network) (data source)

<!-- markdownlint-disable MD013 -->
## Required Inputs

The following input variables are required:

### <a name="input_address_space"></a> [address\_space](#input\_address\_space)

Description: Address space for the virtual network.

Type: `string`

### <a name="input_bastionhost_name"></a> [bastionhost\_name](#input\_bastionhost\_name)

Description: Name of the Bastion host.

Type: `string`

### <a name="input_firewall_name"></a> [firewall\_name](#input\_firewall\_name)

Description: n/a

Type: `string`

### <a name="input_firewall_policy_name"></a> [firewall\_policy\_name](#input\_firewall\_policy\_name)

Description: n/a

Type: `string`

### <a name="input_hub_local_network_gateway_name"></a> [hub\_local\_network\_gateway\_name](#input\_hub\_local\_network\_gateway\_name)

Description: Name of the hub's local network gateway.

Type: `string`

### <a name="input_publicip_names"></a> [publicip\_names](#input\_publicip\_names)

Description: Map of public IP names.

Type:

```hcl
map(object({
    name = string
  }))
```

### <a name="input_rg"></a> [rg](#input\_rg)

Description: Specifies the resource group details.

Type:

```hcl
object({
    resource_group = string
    location       = string
  })
```

### <a name="input_subnet_details"></a> [subnet\_details](#input\_subnet\_details)

Description: Map of subnet details.

Type:

```hcl
map(object({
    subnet_name       = string
    address_prefixes  = string
    delegations       = list(object({
      name              = string
      service_delegation = string
      actions           = list(string)
    }))
  }))
```

### <a name="input_virtual_network_gateway_name"></a> [virtual\_network\_gateway\_name](#input\_virtual\_network\_gateway\_name)

Description: n/a

Type: `string`

### <a name="input_vnet_gateway_connection"></a> [vnet\_gateway\_connection](#input\_vnet\_gateway\_connection)

Description: n/a

Type: `string`

### <a name="input_vnet_name"></a> [vnet\_name](#input\_vnet\_name)

Description: Name of the virtual network.

Type: `string`

### <a name="input_vnet_peerings"></a> [vnet\_peerings](#input\_vnet\_peerings)

Description: Map of VNet peering settings.

Type:

```hcl
map(object({
    allow_forwarded_traffic      = bool
    allow_gateway_transit        = bool
    allow_virtual_network_access = bool
  }))
```

## Optional Inputs

No optional inputs.

## Outputs

The following outputs are exported:

### <a name="output_bastion_host_id"></a> [bastion\_host\_id](#output\_bastion\_host\_id)

Description: The ID of the Azure Bastion host.

### <a name="output_firewall_id"></a> [firewall\_id](#output\_firewall\_id)

Description: The ID of the Azure Firewall.

### <a name="output_public_ip_ids"></a> [public\_ip\_ids](#output\_public\_ip\_ids)

Description: Map of public IP names to their IDs.

### <a name="output_resource_group_id"></a> [resource\_group\_id](#output\_resource\_group\_id)

Description: The ID of the Azure resource group.

### <a name="output_subnet_ids"></a> [subnet\_ids](#output\_subnet\_ids)

Description: Map of subnet names to their IDs in the virtual network.

### <a name="output_virtual_network_gateway_id"></a> [virtual\_network\_gateway\_id](#output\_virtual\_network\_gateway\_id)

Description: The ID of the virtual network gateway.

### <a name="output_virtual_network_id"></a> [virtual\_network\_id](#output\_virtual\_network\_id)

Description: The ID of the virtual network in the hub.

## Modules

No modules.

# Contributing

We welcome contributions to improve this Terraform module.
<!-- END_TF_DOCS -->