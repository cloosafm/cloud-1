variable "ansible_playbook" {}

variable "ssh_user" {
  description = "The SSH username"
  type        = string
}

variable "ssh_pub_key_path" {
  description = "Path to the SSH public key"
  type        = string
}

variable "ssh_priv_key_path" {
  description = "Path to the SSH private key"
  type        = string
}


# provider information
variable "project" {}
variable "credentials_file" {}
variable "region" {
  default = "us-west1"
}
variable "zone" {
  default = "us-west1-c"
}



# template information
variable "template_info" {
  type = object({
    name                      = string
    machine_type              = string
    tags                      = list(string)
    disk_auto_delete          = bool
    disk_boot                 = bool
    os_image                  = string
  })
  default = {
    name                      = "terraform-template"
    machine_type              = "e2-micro"
    tags                      = ["allow-ssh", "website"]
    disk_auto_delete          = true
    disk_boot                 = true
    os_image                  = "ubuntu-os-cloud/ubuntu-2204-lts"
  }
}


# Managed Instance Group information
variable "mig_info" {
  type = object({
    name                      = string
    base_instance_name        = string
    target_size               = number # Number of instances in the group
  })
  default = {
    name                      = "my-instance-group"
    base_instance_name        = "my-instance"
    target_size               = 2
  }
}

variable "tf_network_info" {
  type = object({
    name                    = string
    auto_create_subnetworks = bool
  })
  default = {
    name                    = "tf-network"
    auto_create_subnetworks = false
  }
}

variable "tf_subnet_info" {
  type = object({
    name          = string
    ip_cidr_range = string
    region        = string
  })
  default = {
    name          = "terraform-subnetwork"
    ip_cidr_range = "10.20.0.0/16"
    region        = "us-west1"
  }
}



variable "tf_firewall_info" {
  description = "Information for the firewall rule"
  type = object({
    source_ranges = list(string)
  })
}