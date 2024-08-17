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
![hub](/home/aflalahmad/terraform-hub-and-spoke/Images/hub.png)

### Apply the Terraform configurations :
Deploy the resources using Terraform,
- Initialize Terraform 🔄:
```
terraform init
```
- Plan the Deployment 📝:

```
terraform plan "--var-file=variables.tfvars"
```
- Apply the Configuration ✅:
```
terraform apply "--var-file=variables.tfvars"
```