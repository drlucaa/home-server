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
    bucket                      = "trai-apollo"
    key                         = "provisioning/apollo/terraform.tfstate"
    region                      = "us-east-1"
    endpoints                   = { s3 = "https://nbg1.your-objectstorage.com" }
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

