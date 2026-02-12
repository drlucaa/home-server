output "control_plane_ips" {
  description = "Public IPv4 addresses of the control plane nodes"
  value       = hcloud_server.control_plane[*].ipv4_address
}

output "worker_ips" {
  description = "Public IPv4 addresses of the worker nodes"
  value       = hcloud_server.worker[*].ipv4_address
}

output "load_balancer_ip" {
  description = "Public IPv4 address of the Load Balancer"
  value       = hcloud_load_balancer.k3s.ipv4
}
