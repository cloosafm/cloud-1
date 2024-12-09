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
  }

  network_interface {
    network    = google_compute_network.terraform_network.self_link
    subnetwork = google_compute_subnetwork.terraform_subnet.self_link
    access_config {
      // needed even if empty
    }
  }

  lifecycle {
    create_before_destroy = true
  }

  metadata = {
    ssh-keys       = "${var.ssh_user}:${file(var.ssh_pub_key_path)}"
  }

  metadata_startup_script = <<EOT
    #!/bin/bash
    echo -e '\\033[1;32mWelcome to Cloud-1\\033[0m'
    echo 'Instance is up and running'
    echo 'Current user: $(whoami)'
    echo 'Current directory: $(pwd)'
    echo 'Instance IP: $(curl -s http://metadata.google.internal/computeMetadata/v1/instance/network-interfaces/0/access-configs/0/external-ip -H "Metadata-Flavor: Google")'
  EOT

}

# Managed Instance Group
resource "google_compute_instance_group_manager" "my_instance_group" {
  name               = "my-instance-group"
  base_instance_name = "my-instance"
  target_size        = var.target_size # Number of instances in the group

  version {
  instance_template  = google_compute_instance_template.my_template.self_link
  }
  named_port {
    name = "http"
    port = 80
  }

  provisioner "local-exec" {
    command = <<EOT
      echo "Fetching IPs of instances in the Managed Instance Group..."
      gcloud compute instances list \
        --filter="name~'my-instance'" \
        --format="get(networkInterfaces[0].accessConfigs[0].natIP)" > instance_ip_list
      echo "Instance IPs saved to instance_ip_list"

	  IP_LIST="instance_ip_list"

	  INVENTORY_FILE="../ansible/inventory.yml"
	  echo "---" > $INVENTORY_FILE
	  echo "all:" >> $INVENTORY_FILE
	  echo "  hosts:" >> $INVENTORY_FILE

	  i=1
	  while IFS= read -r ip; do
	  echo "    vm$i:" >> $INVENTORY_FILE
	  echo "      ansible_host: $ip" >> $INVENTORY_FILE
	  i=$((i + 1))
	  done < "$IP_LIST"
	  echo "Inventaire généré dans $INVENTORY_FILE"

	  echo "Waiting for instances to become available..."
      for ip in $(cat instance_ip_list); do
        while ! nc -z -w 5 $ip 22; do
          echo "Waiting for SSH on $ip to respond..."
          sleep 5
        done
        echo "SSH on $ip is available"
      done

      echo "Running Ansible playbook on the fetched IPs..."
      ANSIBLE_HOST_KEY_CHECKING=False  ansible-playbook -i  "../ansible/inventory.yml" -f ${var.target_size} --private-key ${var.ssh_priv_key_path} ${var.ansible_playbook}
    EOT
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