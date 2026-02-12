variable "hcloud_token" {
  description = "Hetzner Cloud API Token"
  type        = string
  sensitive   = true
}

variable "ssh_public_key" {
  description = "Public SSH key content"
  type        = string
}

variable "control_plane_count" {
  description = "Number of control plane nodes"
  type        = number
  default     = 1
}

variable "worker_count" {
  description = "Number of worker nodes"
  type        = number
  default     = 0
}

variable "server_type" {
  description = "Hetzner Server Type for control planes"
  default     = "cx23"
}

variable "worker_server_type" {
  description = "Hetzner Server Type for workers"
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

variable "control_plane_ip_offset" {
  description = "Starting IP offset for control plane nodes (e.g., .10)"
  type        = number
  default     = 10
}

variable "worker_ip_offset" {
  description = "Starting IP offset for worker nodes (e.g., .100)"
  type        = number
  default     = 100
}
