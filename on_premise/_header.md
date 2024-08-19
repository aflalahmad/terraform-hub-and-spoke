# On-Premises Resource Group 🏢
This resource group includes virtual networks (VNets) with subnets, network security groups (NSGs), a virtual network gateway, VPN connection, and virtual network integration. The configuration is designed to be dynamic, allowing for scalable and customizable deployments.

## Prerequisites ⚙️
### Before running this Terraform configuration, ensure you have the following prerequisites:

- Terraform installed on your local machine. 🛠️
- Azure CLI installed and authenticated. 🔑
- Proper access permissions to create resources in the Azure subscription. ✅
## Configuration Details 📝
### Integration with On-Premises Network 🔗
1. Create the Resource Group 🗂️
- Set up a resource group for the on-premises integration to house all related resources.

2. Create the Virtual Network 🌐
- Define a virtual network for the on-premises environment, specifying the address space and other configurations.

3. Create Subnets 🧩
- Segment the virtual network into smaller subnets, each with its own address prefix.

4. Create Public IP 🌍
- Allocate a public IP address for the on-premises VPN gateway.

5. Create a Virtual Network Gateway 🔗
- Establish a virtual network gateway for the on-premises environment to enable site-to-site VPN connections between on-premises and Azure.

6. Create a Local Network Gateway 🌐
- Set up a local network gateway in Azure to represent the on-premises VPN device. Specify the public IP address of the on-premises VPN device and the address space used in the on-premises network.

7. Create a VPN Connection 🔗
- Establish a VPN connection between the Azure virtual network gateway and the on-premises local network gateway. Configure the connection type (IPsec) and the shared key for authentication.

8. Create Network Interface Card (NIC) 💻
- Create a network interface card for each virtual machine in the on-premises network.

9. Create Virtual Machines 🖥️
- Deploy virtual machines in the on-premises network with appropriate configurations.

10. Set Up Route Table for Traffic Routing 🗺️
- Create a route table to manage traffic routing between the on-premises network and the hub. Define routes to direct traffic through the VPN gateway.

11. Associate Route Table with Subnets 🔗
- Associate the route table with the subnets to enforce the routing rules and ensure proper traffic flow between on-premises and Azure.


# Diagram
![onprem](https://github.com/user-attachments/assets/d2a40c04-a1cc-4094-a087-37d2fc3fc19a)


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