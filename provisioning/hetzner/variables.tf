variable "hcloud_token" {
  description = "Hetzner Cloud API Token"
  type        = string
  sensitive   = true
}

variable "ssh_public_key" {
  description = "Public SSH key content"
  type        = string
}

variable "server_type" {
  description = "Hetzner Server Type"
  default     = "cx23"
}

variable "location" {
  description = "Datacenter location"
  default     = "fsn1"
}
