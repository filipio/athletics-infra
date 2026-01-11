# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This repository contains infrastructure-as-code for the **athletics-infra** project, which sets up and configures a single DigitalOcean droplet (`lekkoatletawka.eu`) to serve a web application. The infrastructure is managed through:

- **Terraform**: Infrastructure provisioning on DigitalOcean (droplet, domain, DNS records)
- **Ansible**: Server configuration and service setup (PostgreSQL, Nginx with SSL, SSH, user management)

## Architecture

The project follows a two-stage infrastructure deployment pattern:

1. **Infrastructure Layer (Terraform)**: Creates cloud resources
   - DigitalOcean droplet (Ubuntu 24.04, 1vCPU/1GB RAM, Frankfurt region)
   - Domain and DNS configuration (`lekkoatletawka.eu`)
   - SSH key management

2. **Configuration Layer (Ansible)**: Configures the provisioned server
   - SSH hardening (sshd configuration)
   - User management (sudo users via `users.yml`)
   - PostgreSQL database setup (version 17)
   - Nginx reverse proxy with automatic SSL/TLS certificates via Certbot

## Common Commands

### Terraform

```bash
# Initialize terraform (first time setup)
cd terraform
terraform init

# Plan infrastructure changes
terraform plan

# Apply infrastructure changes (requires DigitalOcean token)
terraform apply

# Output the droplet IP address
terraform output droplet_ipv4_addresses
```

**Note**: Requires `TF_VAR_do_token` environment variable set with your DigitalOcean API token.

### Ansible

```bash
# Run all playbooks in sequence
cd ansible
ansible-playbook create_sudo_users.yml
ansible-playbook sshd.yml
ansible-playbook postgres.yml
ansible-playbook nginx.yml

# Run a specific playbook
ansible-playbook create_sudo_users.yml

# Test connectivity to the host
ansible lekkoatletawka -m ping
```

**Note**: Ensure `ansible/inventory.ini` has the correct SSH configuration. The inventory references `admin` which must be defined in `~/.ssh/config`.

## Key Files and Their Purposes

### Terraform

- `terraform/main.tf`: Defines DigitalOcean resources (droplet, domain, DNS records, SSH keys)

### Ansible

- `ansible/ansible.cfg`: Ansible configuration
- `ansible/inventory.ini`: Host inventory (currently just the main droplet)
- `ansible/create_sudo_users.yml`: Creates users with sudo access from `users.yml`
- `ansible/users.yml`: User definitions (contains SSH public keys)
- `ansible/sshd.yml`: SSH daemon hardening
- `ansible/postgres.yml`: PostgreSQL 17 installation and database setup
- `ansible/nginx.yml`: Nginx installation, SSL certificate setup, and reverse proxy configuration
- `ansible/files/`: Configuration templates and files
  - `secrets.yml`: Database credentials (user, password, database name)
  - `nginx_config.j2`: Nginx reverse proxy template
  - `postgresql.conf`: PostgreSQL configuration
  - `pg_hba.conf`: PostgreSQL host-based authentication
  - `sshd_config`: SSH daemon configuration

## Important Secrets Management

- `ansible/files/secrets.yml`: Contains database credentials (`db_user`, `db_password`, `db_name`)
- `terraform/main.tf`: SSH public keys are defined in the code
- Terraform state files (`.tfstate`) should never be committed

## Domain Configuration

The Nginx playbook currently references `lekkoatletawka.pl` but Terraform configures `lekkoatletawka.eu`. These should be kept in sync.

## Prerequisites for Deployment

1. DigitalOcean account with API token
2. SSH key pair (the public key in `ansible/users.yml` and Terraform's `main.tf`)
3. Ansible installed locally
4. Terraform installed locally
5. SSH config entry for the `admin` host pointing to the droplet's IP

## Database Setup

PostgreSQL is configured with:
- Version 17
- Credentials from `ansible/files/secrets.yml`
- Database and user created via community.postgresql modules
- Host-based authentication configured in `pg_hba.conf`

## SSL/TLS

Nginx uses Certbot for automatic SSL certificate management:
- Domain email: `Filip.Juza.2000@gmail.com` (hardcoded in `nginx.yml`)
- Certificate auto-renewal is handled by Certbot systemd timer