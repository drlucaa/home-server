terraform {
  required_providers {
    hcloud = {
      source  = "hetznercloud/hcloud"
      version = "~> 1.60"
    }
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
}

# Ansible inventory
resource "local_file" "ansible_inventory" {
  content = <<-EOT
    [k3s_nodes]
    ${hcloud_server.k3s_node.name} ansible_host=${hcloud_server.k3s_node.ipv4_address} ansible_user=root
  EOT
  filename = "${path.module}/../ansible/inventory.ini"
}
