terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "6.12.0"
    }
  }
}

provider "google" {
  project     = var.project
  credentials = file(var.credentials_file)
  region      = var.region
  zone        = var.zone
}

# Instance Template
resource "google_compute_instance_template" "my_template" {
  name         = "my-instance-template"
  machine_type = var.instance_info.machine_type

  tags = var.tags_info

  disk {
    auto_delete = true
    boot        = true
    source_image = var.os-image
    # initialize_params {
    #   image = var.os-image
    # }
  }

  network_interface {
    network    = google_compute_network.terraform_network.self_link
    subnetwork = google_compute_subnetwork.terraform_subnet.self_link
    access_config {
      // needed even if empty
    }
  }

  metadata = {
    ssh-keys       = "${var.ssh_user}:${file(var.ssh_pub_key_path)}"
    startup-script = <<-EOT
      #!/bin/bash
      echo "Starting Ansible Playbook on VM"
      apt-get update && apt-get install -y ansible
      echo '${var.ansible_playbook}' > /tmp/playbook.yml
      ansible-playbook /tmp/playbook.yml
    EOT
  }
}

# Managed Instance Group
resource "google_compute_instance_group_manager" "my_instance_group" {
  name               = "my-instance-group"
  base_instance_name = "my-instance"

  target_size        = 2

  version {
  instance_template  = google_compute_instance_template.my_template.self_link
  }
  named_port {
    name = "http"
    port = 80
  }
}

# Network
resource "google_compute_network" "terraform_network" {
  name                    = var.tf_network_info.name
  auto_create_subnetworks = var.tf_network_info.auto_create_subnetworks
}

resource "google_compute_subnetwork" "terraform_subnet" {
  name          = var.tf_subnet_info.name
  ip_cidr_range = var.tf_subnet_info.ip_cidr_range
  region        = var.tf_subnet_info.region
  network       = google_compute_network.terraform_network.id
}

# Firewall Rules
resource "google_compute_firewall" "allow_ssh" {
  name    = "allow-ssh"
  network = google_compute_network.terraform_network.name

  allow {
    protocol = "icmp"
  }

  allow {
    protocol = "tcp"
    ports    = ["22"]
  }

  source_ranges = ["0.0.0.0/0"]
  target_tags   = ["allow-ssh"]
}

resource "google_compute_firewall" "allow_http" {
  name    = "allow-http"
  network = google_compute_network.terraform_network.name

  allow {
    protocol = "tcp"
    ports    = ["80"]
  }

  source_ranges = ["0.0.0.0/0"]
  target_tags   = ["http-server"]
}

resource "google_compute_firewall" "allow_https" {
  name    = "allow-https"
  network = google_compute_network.terraform_network.name

  allow {
    protocol = "tcp"
    ports    = ["443"]
  }

  source_ranges = ["0.0.0.0/0"]
  target_tags   = ["https-server"]
}