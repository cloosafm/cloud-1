variable "project" {}
variable "credentials_file" {}

variable "ssh-keys" {
  description = "SSH keys for the project"
  type        = string
}

# variable "ssh-file" {
#   description = "SSH public key file"
#   type        = string
  
# }

variable "region" {
    default = "us-west1"
}

variable "zone" {
    default = "us-west1-c"
}

variable "os-image" {
    default = "ubuntu-os-cloud/ubuntu-2204-lts"
}

variable "instance_info" {
    type = object({
      name = string
      machine_type = string
      zone = string
      allow_stopping_for_update = bool
    })
    default = {
      name = "terraform-instance"
      machine_type = "e2-micro"
      zone = "us-west1-a"
      allow_stopping_for_update = true
    }
}

variable "tf_network_info" {
    type = object({
      name = string
      auto_create_subnetworks = bool
    })
    default = {
      name = "terraform-network"
      auto_create_subnetworks = false
    }
}

variable "tf_subnet_info" {
    type = object({
      name = string
      ip_cidr_range = string
      region = string
    })
    default = {
      name = "terraform-subnetwork"
      ip_cidr_range = "10.20.0.0/16"
      region = "us-west1"
    }
}