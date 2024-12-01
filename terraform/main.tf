terraform {
  required_providers {
    digitalocean = {
      source  = "digitalocean/digitalocean"
      version = "~> 2.0"
    }
  }
}

# Set the variable value in *.tfvars file
# or using -var="do_token=..." CLI option
variable "do_token" {
  default = "do_token"
}

# Configure the DigitalOcean Provider
provider "digitalocean" {
  token = var.do_token
}

locals {
  ssh_keys = {
    "admin" = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIFvSGrF8FBMPvr1OlzqvjPQnFbbtA6+7HLGKygRULT3A filip@Pikachu"
  }
}

resource "digitalocean_ssh_key" "main" {
  for_each   = local.ssh_keys
  name       = each.key
  public_key = each.value
}

resource "digitalocean_droplet" "lekkoatletawka" {
  image      = "ubuntu-24-04-x64"
  name       = "lekkoatletawka-machine"
  region     = "fra1"
  size       = "s-1vcpu-1gb"
  backups    = false
  monitoring = false
  ssh_keys   = [for key in digitalocean_ssh_key.main : key.id]
}

resource "digitalocean_domain" "lekkoatletawka" {
  name       = "lekkoatletawka.pl"
  ip_address = digitalocean_droplet.lekkoatletawka.ipv4_address
}

output "droplet_ipv4_addresses" {
  value = digitalocean_droplet.lekkoatletawka.ipv4_address
}