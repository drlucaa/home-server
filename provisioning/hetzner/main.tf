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

# --- SSH KEY ---
resource "hcloud_ssh_key" "default" {
  name       = "home-server-key"
  public_key = var.ssh_public_key
}

# --- FIREWALL ---
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
    port      = "6443"
    source_ips = ["0.0.0.0/0", "::/0"]
  }
  rule {
    direction = "in"
    protocol  = "tcp"
    port      = "80"
    source_ips = ["0.0.0.0/0", "::/0"]
  }
  rule {
    direction = "in"
    protocol  = "tcp"
    port      = "443"
    source_ips = ["0.0.0.0/0", "::/0"]
  }
}

# --- NETWORK ---
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

# --- LOAD BALANCER ---

resource "hcloud_load_balancer" "k3s" {
  name               = "k3s-lb"
  load_balancer_type = "lb11"
  location           = var.location
}

# Attach LB to the private network
resource "hcloud_load_balancer_network" "k3s" {
  load_balancer_id = hcloud_load_balancer.k3s.id
  network_id       = hcloud_network.k3s.id
  ip               = "10.0.1.5"
}

resource "hcloud_load_balancer_service" "kube_api" {
  load_balancer_id = hcloud_load_balancer.k3s.id
  protocol         = "tcp"
  listen_port      = 6443
  destination_port = 6443

  health_check {
    protocol = "tcp"
    port     = 6443
    interval = 10
    timeout  = 5
    retries  = 3
  }
}

resource "hcloud_load_balancer_service" "http" {
  load_balancer_id = hcloud_load_balancer.k3s.id
  protocol         = "tcp"
  listen_port      = 80
  destination_port = 80

  health_check {
    protocol = "tcp"
    port     = 80
    interval = 10
    timeout  = 5
    retries  = 3
  }
}

resource "hcloud_load_balancer_service" "https" {
  load_balancer_id = hcloud_load_balancer.k3s.id
  protocol         = "tcp"
  listen_port      = 443
  destination_port = 443

  health_check {
    protocol = "tcp"
    port     = 443
    interval = 10
    timeout  = 5
    retries  = 3
  }
}

# --- CONTROL PLANE NODES ---

resource "hcloud_placement_group" "control_plane" {
  name = "k3s-control-spread"
  type = "spread"
}

resource "hcloud_server" "control_plane" {
  count       = var.control_plane_count
  name        = "k3s-control-${count.index + 1}"
  image       = "debian-13"
  server_type = var.server_type
  location    = var.location
  ssh_keys    = [hcloud_ssh_key.default.id]
  firewall_ids = [hcloud_firewall.k3s.id]
  placement_group_id = hcloud_placement_group.control_plane.id

  public_net {
    ipv4_enabled = true
    ipv6_enabled = true
  }

  network {
    network_id = hcloud_network.k3s.id
    ip         = "10.0.1.${10 + count.index}"
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

resource "hcloud_load_balancer_target" "control_plane" {
  count            = var.control_plane_count
  type             = "server"
  load_balancer_id = hcloud_load_balancer.k3s.id
  server_id        = hcloud_server.control_plane[count.index].id
  use_private_ip   = true
  
  depends_on       = [hcloud_load_balancer_network.k3s]
}

# --- WORKER NODES ---
resource "hcloud_server" "worker" {
  count       = var.worker_count
  name        = "k3s-worker-${count.index + 1}"
  image       = "debian-13"
  server_type = var.worker_server_type
  location    = var.location
  ssh_keys    = [hcloud_ssh_key.default.id]
  firewall_ids = [hcloud_firewall.k3s.id]

  public_net {
    ipv4_enabled = true
    ipv6_enabled = true
  }

  network {
    network_id = hcloud_network.k3s.id
    ip         = "10.0.1.${100 + count.index}"
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

resource "hcloud_load_balancer_target" "worker" {
  count            = var.worker_count
  type             = "server"
  load_balancer_id = hcloud_load_balancer.k3s.id
  server_id        = hcloud_server.worker[count.index].id
  use_private_ip   = true

  depends_on       = [hcloud_load_balancer_network.k3s]
}

# --- ANSIBLE INVENTORY ---
resource "local_file" "ansible_inventory" {
  content = yamlencode({
    k3s_cluster = {
      children = {
        # Control Plane Nodes (Mapped to 'server')
        server = {
          hosts = {
            for i, server in hcloud_server.control_plane :
            server.name => {
              ansible_host = server.ipv4_address
              ansible_user = "admin"
              k3s_node_ip  = "10.0.1.${10 + i}"
            }
          }
        }
        # Worker Nodes (Mapped to 'agent')
        agent = {
          hosts = {
            for i, server in hcloud_server.worker :
            server.name => {
              ansible_host = server.ipv4_address
              ansible_user = "admin"
              k3s_node_ip  = "10.0.1.${100 + i}"
            }
          }
        }
      }
    }
  })
  filename = "${path.module}/../ansible/inventory.yaml"
}
