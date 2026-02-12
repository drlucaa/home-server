output "server_ips" {
  description = "Public IPv4 addresses of the server nodes"
  value       = hcloud_server.server[*].ipv4_address
}

output "agent_ips" {
  description = "Public IPv4 addresses of the agent nodes"
  value       = hcloud_server.agent[*].ipv4_address
}

output "load_balancer_ip" {
  description = "Public IPv4 address of the Load Balancer"
  value       = hcloud_load_balancer.k3s.ipv4
}
