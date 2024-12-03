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

resource "google_compute_instance" "my_instance" {
  name                      = var.instance_info.name
  machine_type              = var.instance_info.machine_type
  zone                      = var.instance_info.zone
  allow_stopping_for_update = var.instance_info.allow_stopping_for_update

  tags = ["allow-ssh"] // optional, can be used to determine if this is instance is for dev, test, prod, etc
  // should probably be in variables file, can be used as a map
  // see also the use of labels

  boot_disk {
    initialize_params {
      image = var.os-image
    }
  }

  network_interface {
    network    = google_compute_network.terraform_network.self_link
    subnetwork = google_compute_subnetwork.terraform_subnet.self_link
    access_config {
      // needed even if empty
    }
  }

  metadata = {
    ssh-keys = "${var.ssh_user}:${file(var.ssh_pub_key_path)}"
  }


  provisioner "remote-exec" {
    inline = [
      "echo '\\033[1;32mWelcome to Cloud-1\\033[0m'",
      "echo 'Instance is up and running'",
      "bash -c 'echo Current user: $(whoami)'",
      "bash -c 'echo Current directory: $(pwd)'",
      "echo 'Instance IP: ${self.network_interface.0.access_config.0.nat_ip}'"
    ]


    connection {
        host        = google_compute_instance.my_instance.network_interface.0.access_config.0.nat_ip
        type        = "ssh"
        user        = "${var.ssh_user}"
        private_key = "${file("${var.ssh_priv_key_path}")}"
    }
  }

  provisioner "local-exec" {  
    command = "ansible-playbook -i '${google_compute_instance.my_instance.network_interface.0.access_config.0.nat_ip},' --private-key ${var.ssh_priv_key_path} ../ansible/playbook.yml"
  }
}


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

resource "google_compute_firewall" "allow-ssh" {
  name    = "test-firewall"
  network = google_compute_network.terraform_network.name

  allow {
    protocol = "icmp"
  }

  allow {
    protocol = "tcp"
    ports    = ["22"]
  }

  source_tags   = ["web"]
  source_ranges = ["0.0.0.0/0"]
  target_tags   = ["allow-ssh"]
}
