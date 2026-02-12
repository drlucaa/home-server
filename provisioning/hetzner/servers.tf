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
