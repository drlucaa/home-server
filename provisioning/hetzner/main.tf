terraform {
  required_providers {
    hcloud = {
      source  = "hetznercloud/hcloud"
      version = "~> 1.60"
    }

    local = {
      source  = "hashicorp/local"
      version = "~> 2.6"
    }
  }

  backend "s3" {
    bucket                      = "traitofustate"
    key                         = "provisioning/hetzner/terraform.tfstate"
    region                      = "us-east-1"
    endpoints                   = { s3 = "https://fsn1.your-objectstorage.com" }

    skip_credentials_validation = true
    skip_region_validation      = true
    skip_requesting_account_id  = true
    skip_metadata_api_check     = true
    use_path_style              = true
  }
}

provider "hcloud" {
  token = var.hcloud_token
}

# Uploaded public SSH key
resource "hcloud_ssh_key" "default" {
  name       = "home-server-key"
  public_key = var.ssh_public_key
}

# Firewall
resource "hcloud_firewall" "k3s" {
  name = "k3s-firewall"
  rule {
    direction = "in"
    protocol  = "tcp"
    port      = "22"
    source_ips = ["0.0.0.0/0", "::/0"]
  }
  rule {
    direction = "in"
    protocol  = "tcp"
    port      = "6443" # Kubernetes API
    source_ips = ["0.0.0.0/0", "::/0"]
  }
  rule {
    direction = "in"
    protocol  = "tcp"
    port      = "80" # Ingress HTTP
    source_ips = ["0.0.0.0/0", "::/0"]
  }
  rule {
    direction = "in"
    protocol  = "tcp"
    port      = "443" # Ingress HTTPS
    source_ips = ["0.0.0.0/0", "::/0"]
  }
  # rule {
  #   direction = "in"
  #   protocol  = "udp"
  #   port      = "51820" # NetBird later on
  #   source_ips = ["0.0.0.0/0", "::/0"]
  # }
}

# Private Network
resource "hcloud_network" "k3s" {
  name     = "k3s-network"
  ip_range = "10.0.0.0/16"
}

resource "hcloud_network_subnet" "k3s" {
  network_id   = hcloud_network.k3s.id
  type         = "cloud"
  network_zone = "eu-central"
  ip_range     = "10.0.1.0/24"
}

# The VPS Instance
resource "hcloud_server" "k3s_node" {
  name        = "k3s-server-1"
  image       = "debian-13"
  server_type = var.server_type
  location    = var.location
  ssh_keys    = [hcloud_ssh_key.default.id]
  firewall_ids = [hcloud_firewall.k3s.id]

  public_net {
    ipv4_enabled = true
    ipv6_enabled = true
  }

  network {
    network_id = hcloud_network.k3s.id
    ip         = "10.0.1.5" # Explicitly setting a static IP is recommended for servers
  }

  user_data = <<-EOF
    #cloud-config
    users:
      - name: admin
        groups: users, sudo
        sudo: ALL=(ALL) NOPASSWD:ALL
        shell: /bin/bash
        ssh_authorized_keys:
          - "${hcloud_ssh_key.default.public_key}"
  
    disable_root: true
    ssh_pwauth: false
  EOF
}

# Ansible inventory
resource "local_file" "ansible_inventory" {
  content = <<-EOT
    [k3s_primary]
    ${hcloud_server.k3s_node.name} ansible_host=${hcloud_server.k3s_node.ipv4_address} ansible_user=admin
  EOT
  filename = "${path.module}/../ansible/inventory.ini"
}
