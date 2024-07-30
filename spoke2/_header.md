# Spoke2 Resource Group

This Resource Group  including virtual networks (VNets) with subnets and network security groups (NSGs) and virtual machine scale set. The configuration is designed to be dynamic, allowing for scalable and customizable deployments.

Step-by-Step Guide
1. Create Resource Group
- First, create a resource group where all resources will be deployed.

2. Create Virtual Network
- Next, create a virtual network.

3. Create Subnets
- Create multiple subnets within the virtual network.

4. Create Network Security Groups
- Define Network Security Groups (NSGs) to manage inbound and outbound traffic rules for each subnet.

5. Associate NSGs with Subnets
- Link each subnet with its corresponding NSG to enforce the traffic rules defined.

6. Create Public IP for Application Gateway
- Set up a public IP address for the Application Gateway, ensuring it has a static allocation method and is of the Standard SKU.

7. Create Application Gateway
- Deploy an Application Gateway in its dedicated subnet, configuring it with the necessary settings such as IP configurations, front-end ports, back-end address pools, HTTP settings, listeners, and routing rules.

8. Retrieve Secrets from Key Vault
- Access the Azure Key Vault to retrieve the VM admin username and password, ensuring secure credential management.

9. Create Virtual Machine Scale Set
- Deploy a Virtual Machine Scale Set (VMSS) with the desired configuration, including instance count, admin credentials, source image, and network interface settings.

10.  Set Up Daily Backup for VMs
- Configure a Recovery Services Vault and define a backup policy with daily backups, retention settings, and protection for VM scale sets.

11.  Apply Azure Policy for Regional Deployment
- Create and assign an Azure Policy to limit service deployments to specific regions, ensuring compliance with organizational policies.

12.  Apply Azure Policy at Resource Group Level
- Scope all Azure Policies to the Resource Group level for better management and control.

13.  Create Route Table for Communication Between Spokes
- Set up a route table to manage traffic between spokes through the firewall, ensuring secure and efficient communication within the network architecture.


# Diagram

![Screenshot 2024-07-23 102202](https://github.com/user-attachments/assets/418e3838-b115-410f-ad80-5fca878ec5ad)
