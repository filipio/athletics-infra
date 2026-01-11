terraform {
  required_providers {
    digitalocean = {
      source  = "digitalocean/digitalocean"
      version = "~> 2.0"
    }
  }
}

variable "do_token" {
  description = "DigitalOcean API token"
  type        = string
  sensitive   = true
}

provider "digitalocean" {
  token = var.do_token
}

locals {
  ssh_keys = {
    "admin" = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIONqH69HVrisJAFIbNq5ZltlDWvkXXGpDR3En8I671l/ filip.juza.2000@gmail.com"
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
  name       = "lekkoatletawka.eu"
  ip_address = digitalocean_droplet.lekkoatletawka.ipv4_address
}

resource "digitalocean_record" "www" {
  domain = digitalocean_domain.lekkoatletawka.name
  type   = "CNAME"
  name   = "www"
  value  = "${digitalocean_domain.lekkoatletawka.name}." # trailing dot is required
}

output "droplet_ipv4_addresses" {
  value = digitalocean_droplet.lekkoatletawka.ipv4_address
}