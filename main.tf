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
  name         = "terraform-instance"
  machine_type = "f1-micro"
  zone         = "us-central1-a"
  allow_stopping_for_update = true

  tags = ["dev"]

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

resource "google_compute_network" "terraform_network"{
    name = "terraform-network"
    auto_create_subnetworks = false
}

resource "google_compute_subnetwork" "terraform_subnet" {
    name = "terraform-subnetwork"
    ip_cidr_range = "10.20.0.0/16"
    region = "us-central1"
    network = google_compute_network.terraform_network.id


}


