output "control_plane_ips" {
  description = "Public IPv4 addresses of the control plane nodes"
  value       = hcloud_server.control_plane[*].ipv4_address
}

output "worker_ips" {
  description = "Public IPv4 addresses of the worker nodes"
  value       = hcloud_server.worker[*].ipv4_address
}

output "primary_control_plane_ip" {
  description = "The public IPv4 address of the first control plane node (for initial SSH/K3s setup)"
  value       = length(hcloud_server.control_plane) > 0 ? hcloud_server.control_plane[0].ipv4_address : null
}

output "load_balancer_ip" {
  description = "Public IPv4 address of the Load Balancer"
  value       = hcloud_load_balancer.k3s.ipv4
}
