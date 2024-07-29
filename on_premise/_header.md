# Onpremise resource group

This resource groups including virtual networks (VNets) with subnets and network security groups (NSGs) adn virtual network gateway,vpn connection and virtual network integration etc.. The configuration is designed to be dynamic, allowing for scalable and customizable deployments.

## Integration with On-Premises Network
- Create the Resource Group

Set up a resource group for the on-premises integration to house all related resources.
- Create the Virtual Network

Define a virtual network for the on-premises environment, specifying the address space and other configurations.
- Create Subnets

Segment the virtual network into smaller subnets, each with its own address prefix.
- Create Public IP

Allocate a public IP address for the on-premises VPN gateway.
- Create a Virtual Network Gateway

Establish a virtual network gateway for the on-premises environment to enable site-to-site VPN connections between on-premises and Azure.
- Create a Local Network Gateway

Set up a local network gateway in Azure to represent the on-premises VPN device.
Specify the public IP address of the on-premises VPN device and the address space used in the on-premises network.
- Create a VPN Connection

Establish a VPN connection between the Azure virtual network gateway and the on-premises local network gateway.
Configure the connection type (IPsec) and the shared key for authentication.

- Create Network Interface Card (NIC)

Create a network interface card for each virtual machine in the on-premises network.
- Create Virtual Machines

Deploy virtual machines in the on-premises network with appropriate configurations.
- Set Up Route Table for Traffic Routing

Create a route table to manage traffic routing between the on-premises network and the hub.
Define routes to direct traffic through the VPN gateway.
- Associate Route Table with Subnets

Associate the route table with the subnets to enforce the routing rules and ensure proper traffic flow between on-premises and Azure.






# Diagram
![Screenshot 2024-07-23 102131](https://github.com/user-attachments/assets/b257736a-0d7e-4af4-b70c-fa8add008d65)