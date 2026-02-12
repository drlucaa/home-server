variable "hcloud_token" {
  description = "Hetzner Cloud API Token"
  type        = string
  sensitive   = true
}

variable "ssh_public_key" {
  description = "Public SSH key content"
  type        = string
}

variable "server_count" {
  description = "Number of server (control plane) nodes"
  type        = number
  default     = 1
}

variable "agent_count" {
  description = "Number of agent (worker) nodes"
  type        = number
  default     = 0
}

variable "server_type" {
  description = "Hetzner Server Type for servers"
  default     = "cx23"
}

variable "agent_type" {
  description = "Hetzner Server Type for agents"
  default     = "cx23"
}

variable "location" {
  description = "Datacenter location"
  default     = "nbg1"
}

variable "subnet_prefix" {
  description = "The first 3 octets of the private subnet"
  type        = string
  default     = "10.0.1"
}

variable "load_balancer_private_ip" {
  description = "Private IP for the Load Balancer"
  type        = string
  default     = "10.0.1.5"
}

variable "server_ip_offset" {
  description = "Starting IP offset for server nodes (e.g., .10)"
  type        = number
  default     = 10
}

variable "agent_ip_offset" {
  description = "Starting IP offset for agent nodes (e.g., .100)"
  type        = number
  default     = 100
}
