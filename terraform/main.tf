terraform {
  required_providers {
    google = {
      source = "hashicorp/google"
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

resource "google_compute_instance" "my_instance" {
  name         = var.instance_info.name
  machine_type = var.instance_info.machine_type
  zone         = var.instance_info.zone
  allow_stopping_for_update = var.instance_info.allow_stopping_for_update

  tags = ["dev"] // optional, can be used to determine if this is instance is for dev, test, prod, etc
  // should probably be in variables file, can be used as a map
  // see also the use of labels

  boot_disk {
    initialize_params {
      image = var.os-image
    }
  }

  network_interface {
    network = google_compute_network.terraform_network.self_link
    subnetwork = google_compute_subnetwork.terraform_subnet.self_link
    access_config { 
      // needed even if empty
    }
  }

  metadata = {
    ssh-keys = "acloos:${file("~/.ssh/id_rsa.pub")}"
  }
}

resource "google_compute_network" "terraform_network"{
    name = var.tf_network_info.name
    auto_create_subnetworks = var.tf_network_info.auto_create_subnetworks
}

resource "google_compute_subnetwork" "terraform_subnet" {
    name = var.tf_subnet_info.name
    ip_cidr_range = var.tf_subnet_info.ip_cidr_range
    region = var.tf_subnet_info.region
    network = google_compute_network.terraform_network.id


}


