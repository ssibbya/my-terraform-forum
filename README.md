# Scalable and Highly Available Forum Web App using Terraform on AWS

This project sets up a scalable and highly available forum-style web application infrastructure using AWS and Terraform Cloud. The application includes a VPC, public/private subnets, NAT gateway, ALB, Auto Scaling EC2 instances, and an RDS PostgreSQL database.

---

## Architecture Overview

**Main Components:**
- **VPC** with public and private subnets across two AZs
- **Internet Gateway** and **NAT Gateway**
- **Application Load Balancer (ALB)** to distribute traffic
- **Auto Scaling Group** of EC2 instances (in private subnets)
- **Amazon RDS** for PostgreSQL database in Multi-AZ
- **Security Groups** for controlled access
- **VPC Endpoints** for EC2 SSM access
- **IAM Roles** for EC2

---

## Infrastructure Diagram

![architecture](https://github.com/user-attachments/assets/b7b765cd-3342-49e0-a1aa-0efdaa7dfc85)

---

## Terraform Cloud Setup

This project is deployed using **Terraform Cloud**.

### Steps to Use Terraform Cloud

1. **Create a Workspace** in Terraform Cloud.
2. **Connect your Terraform Cloud Workspace to the GitHub repository** containing this Terraform code.
3. In **Terraform Cloud Workspace Variables**, add the following Environment Variables (with `sensitive` checked where needed):

| Variable Name            | Value                       | Sensitive |
|--------------------------|-----------------------------|-----------|
| AWS_ACCESS_KEY_ID        | Your AWS Access Key ID      | Yes       |
| AWS_SECRET_ACCESS_KEY    | Your AWS Secret Access Key  | Yes       |
| TF_VAR_db_username       | PostgreSQL DB Username      | Yes       |
| TF_VAR_db_password       | PostgreSQL DB Password      | Yes       |

4. **Enable Remote Backend Locking**
   In `main.tf` or your backend file, use:

```hcl
terraform {
  backend "remote" {
    organization = "your-org-name"

    workspaces {
      name = "forum-webapp"
    }

    # Locking enabled by default in Terraform Cloud
    # use_lockfile = true is recommended
  }
}
```

### Why use `use_lockfile = true`?
Instead of specifying a separate DynamoDB table for state locking (common in `S3` backends), Terraform Cloud **automatically handles** state locking for you. Setting `use_lockfile = true` is a safe and recommended approach to ensure that state is not modified concurrently. This simplifies setup and avoids managing additional AWS resources like DynamoDB.

---

## Deployment Instructions

### Prerequisites
- AWS Account with IAM credentials
- Terraform Cloud account
- GitHub repository with this code

### 1. Push Your Code to GitHub
Ensure your Terraform code is available in a GitHub repository.

### 2. Connect GitHub Repo to Terraform Cloud Workspace
- Navigate to your Workspace in Terraform Cloud.
- Under "Version Control", select GitHub and authorize access.
- Select the repository where this Terraform project is stored.

### 3. Configure Workspace Variables
- Set the environment variables as described above.

### 4. Trigger a Plan and Apply
- Trigger a new plan in the Terraform Cloud workspace.
- Review the changes and apply them to deploy the infrastructure.
<img width="995" alt="terraplan" src="https://github.com/user-attachments/assets/43c5ad47-93ac-4856-a138-c24f3583b66f" />

### 5. Verify Resources in AWS
- VPC and subnets created
- EC2 instances launched with Apache
- ALB URL serves a basic web page: `Forum App Running!`
- RDS PostgreSQL is deployed with Multi-AZ

---

## Notes
- The web server is a basic Apache server. You can modify the `user_data` to serve a full web application.

---

## Cleanup
To avoid unnecessary charges, destroy the resources:
```bash
terraform destroy
```

Or from the Terraform Cloud workspace: go to "Actions > Queue destroy plan".

---
