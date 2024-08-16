# Terraform-Hub and Spoke Architecture
![hub and spoke final](Images/hub_spoke_overall.png)



# Project Documentation

# Resource Groups

## Backend Resource Group Workflow
This documentation outlines the resources added to the backend resource group using Terraform. The setup includes a Resource Group, a Storage Account, and a Storage Container, typically used for storing Terraform state files.

### 1. Resource Group
A Resource Group is created to organize and manage the associated resources. This is the foundation where all other resources will reside.

<img src="https://via.placeholder.com/400x200.png?text=Resource+Group" alt="Resource Group" style="max-width: 100%; height: auto;">
Description:

The Resource Group defines a logical container into which Azure resources, like storage accounts and containers, are deployed and managed.
### 2. Storage Account
Within the Resource Group, a Storage Account is created. This account provides secure storage for the Terraform state files, ensuring their integrity and availability.

<img src="https://via.placeholder.com/400x200.png?text=Storage+Account" alt="Storage Account" style="max-width: 100%; height: auto;">
Description:

The Storage Account is configured to use Standard performance with Locally Redundant Storage (LRS), which keeps three copies of the data within a single data center.
Metadata tags are applied to categorize and manage the Storage Account effectively.
### 3. Storage Container
A Storage Container is created within the Storage Account to specifically store Terraform state files. The container is set to private, ensuring that the state files are not publicly accessible.

<img src="https://via.placeholder.com/400x200.png?text=Storage+Container" alt="Storage Container" style="max-width: 100%; height: auto;">
Description:

The Storage Container is used to store state files securely, which are crucial for maintaining the infrastructure's desired state.

### On-Premises Resource Group
- Detailed overview of on-premises resource group configurations.
- Guidelines for setup, management, and maintenance.
- Best practices for optimizing performance and security.

### Spoke 01 Resource Group
- Configuration and deployment details for Spoke 01.
- Integration with hub and other spokes.
- Security, monitoring, and optimization guidelines.

### Spoke 02 Resource Group
- User-Defined Route (UDR) setup and management.
- Subnet association and traffic routing through firewall.
- Optimization and troubleshooting tips.

### Spoke 03 Resource Group
- Configuration and deployment details for Spoke 03.
- Integration with Azure App Service and virtual network.
- Security and monitoring guidelines.

### Hub Resource Group
- Centralized services and networking overview.
- Integration and communication between spokes.
- Maintenance and monitoring best practices.

### Azure App Service Resource Group
- Deployment and configuration of Azure App Service.
- Integration with virtual network and other services.
- Performance tuning and security practices.

### Azure Policies Resource Group
- Policy definitions and scope at the resource group level.
- Enabling diagnostics logs and region limitations.
- Compliance and auditing guidelines.

### VM Backup Resource Group
- Configuration for regional replication of VM backups.
- Backup scheduling and retention policies.
- Recovery and disaster recovery planning.

## Footer

### Feedback
**Was this document helpful?** </br>
[![Documentation](https://img.shields.io/badge/Yes-blue?style=for-the-badge)](#) [![Documentation](https://img.shields.io/badge/No-blue?style=for-the-badge)](#)


<div align="right"><h4>Written By,</h4>
<a href="https://www.linkedin.com/in/aflalahmadav/">Aflal ahmad</a>
<h6>Cloud Engineer Intern @ CloudSlize</h6>
</div>

<div align="center">


[![Your Button Text](https://img.shields.io/badge/Thank_you!-Your_Color?style=for-the-badge)](#)

</div>
