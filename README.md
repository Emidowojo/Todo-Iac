# Todo Application Infrastructure Deployment

Deploy a containerized Todo application to AWS using **Terraform** and **Ansible** with a single command.

## Table of Contents
- [Requirements](#requirements)
- [Setup Instructions](#setup-instructions)
- [Infrastructure Overview](#infrastructure-overview)
- [Deployment Process](#deployment-process)
- [Traefik Configuration (SSL/TLS)](#traefik-configuration-ssltls)
- [Environment Variables](#environment-variables)
- [Security Considerations](#security-considerations)
- [Troubleshooting](#troubleshooting)
- [Destroying Infrastructure](#destroying-infrastructure)

## Requirements

### **Software**
- AWS Account with IAM user credentials
- Terraform v1.6+
- Ansible v2.15+
- AWS CLI v2.13+
- SSH client
- Git

### **AWS Resources**
- EC2 Instance (**t2.micro** recommended for free tier)
- Security Groups
- Key Pair

## Setup Instructions

### **1. Install Dependencies**

#### **Terraform:**
```bash
# macOS
brew tap hashicorp/tap
brew install hashicorp/tap/terraform

# Linux
sudo apt-get update && sudo apt-get install -y terraform
```

#### **Ansible:**
```bash
# macOS
brew install ansible

# Linux
sudo apt install ansible -y
```

#### **AWS CLI:**
```bash
# macOS
brew install awscli

# Linux
sudo apt install awscli -y
```

### **2. Configure AWS Credentials**
```bash
aws configure
```

### **3. SSH Key Setup**
```bash
ssh-keygen -t rsa -b 4096 -f ~/.ssh/todo-app-key
aws ec2 import-key-pair --key-name "todo-app-key" --public-key-material fileb://~/.ssh/todo-app-key.pub
```

### **4. Terraform Configuration**
Create `terraform.tfvars`:
```hcl
aws_region        = "us-east-1"
instance_type     = "t2.micro"
ssh_key_name      = "todo-app-key"
app_repo_url      = "https://github.com/yourusername/your-forked-todo-app.git"
domain_name       = "yourdomain.com"
ssh_private_key_path = "~/.ssh/todo-app-key"
```

### **5. Ansible Configuration**
Edit `ansible/roles/deployment/templates/.env.j2`:
```bash
JWT_SECRET=your_generated_secret_here
```
Generate a strong secret:
```bash
openssl rand -base64 48
```

## Infrastructure Overview

### **AWS Components**
- **EC2 Instance:** Ubuntu 22.04 (**t2.micro**)
- **Security Groups:**
  - SSH access (**port 22**) restricted to your IP
  - HTTP/HTTPS (**ports 80/443**) for application access
- **Key Pair:** Used for SSH authentication

### **Deployment Flow**
1. **Terraform provisions AWS infrastructure**
2. **Ansible configures the EC2 instance**:
   - Installs Docker & Docker Compose
   - Clones the application repository
   - Deploys the application using **Docker Compose**
   - Configures **SSL/TLS using Traefik**

## Deployment Process

### **1. Initialize Terraform**
```bash
cd terraform/
terraform init
```

### **2. Apply Configuration**
```bash
terraform apply -auto-approve
```
> **Expected Output:**
> - `Apply complete! Resources: X added, 0 changed, 0 destroyed.`
> - The EC2 public IP will be displayed.

### **3. Post-Deployment Setup**
Get EC2 **public IP** from Terraform output:
```bash
echo $(terraform output -raw ec2_public_ip)
```

Configure **DNS in Hostinger**:
- Create an **A record** pointing to the **EC2 IP**
  - Example: `@ 3600 IN A 54.210.239.101`
- Wait **5-60 minutes** for DNS propagation

### **4. Verify Deployment**
```bash
curl https://yourdomain.com
```

## Traefik Configuration (SSL/TLS)

### **How Traefik is Set Up**
1. **Ansible installs Traefik** on the EC2 instance
2. **Traefik is configured via `docker-compose.yml`**
3. **LetsEncrypt issues SSL certificates automatically**

> **Example `docker-compose.override.yml` for Traefik:**
```yaml
version: '3.8'
services:
  traefik:
    image: traefik:v2.9
    command:
      - "--api.insecure=true"
      - "--providers.docker"
      - "--entrypoints.web.address=:80"
      - "--entrypoints.websecure.address=:443"
    ports:
      - "80:80"
      - "443:443"
    volumes:
      - /var/run/docker.sock:/var/run/docker.sock
      - ./traefik.yml:/traefik.yml
```

## Environment Variables

| Variable | Location | Description |
|----------|----------|-------------|
| JWT_SECRET | `ansible/roles/deployment/templates/.env.j2` | Secret for JWT token encryption |
| AWS_ACCESS_KEY_ID | AWS CLI configuration | AWS authentication |
| AWS_SECRET_ACCESS_KEY | AWS CLI configuration | AWS authentication |

## Security Considerations
- **SSH access** restricted to your IP (`YOUR_IP/32` in `security.tf`)
- **Sensitive data** (SSH keys, JWT secrets) are **excluded from version control**
- **Regular security updates** applied via Ansible

## Troubleshooting

### **Common Issues & Fixes**

#### **1. "ansible-playbook: command not found"**
> **Fix:** Install Ansible and verify PATH:
```bash
ansible-playbook --version
```

#### **2. SSH Connection Refused**
> **Fix:** Verify:
- Correct **IP in security group**
- Proper **SSH key configuration**
- **EC2 instance status** in AWS console

#### **3. DNS Not Propagating**
> **Fix:** Check with:
```bash
dig yourdomain.com +short
```

## Destroying Infrastructure
```bash
terraform destroy -auto-approve
```

## `.gitignore` (Add these for security)
```
*.tfstate
*.tfstate.backup
.terraform/
.env
*.pem
*.pub
terraform.tfvars
inventory.ini
```

## License
MIT License - See LICENSE for details.

---
