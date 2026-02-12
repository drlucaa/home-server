# --- SERVER NODES ---
resource "hcloud_placement_group" "server" {
  name = "k3s-server-spread"
  type = "spread"
}

resource "hcloud_server" "server" {
  count              = var.server_count
  name               = "k3s-server-${count.index + 1}"
  image              = "debian-13"
  server_type        = var.server_type
  location           = var.location
  ssh_keys           = [hcloud_ssh_key.default.id]
  firewall_ids       = [hcloud_firewall.k3s.id]
  placement_group_id = hcloud_placement_group.server.id

  public_net {
    ipv4_enabled = true
    ipv6_enabled = true
  }

  network {
    network_id = hcloud_network.k3s.id
    ip         = "${var.subnet_prefix}.${var.server_ip_offset + count.index}"
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

# --- AGENT NODES ---
resource "hcloud_server" "agent" {
  count        = var.agent_count
  name         = "k3s-agent-${count.index + 1}"
  image        = "debian-13"
  server_type  = var.agent_type
  location     = var.location
  ssh_keys     = [hcloud_ssh_key.default.id]
  firewall_ids = [hcloud_firewall.k3s.id]

  public_net {
    ipv4_enabled = true
    ipv6_enabled = true
  }

  network {
    network_id = hcloud_network.k3s.id
    ip         = "${var.subnet_prefix}.${var.agent_ip_offset + count.index}"
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
