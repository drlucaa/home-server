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
