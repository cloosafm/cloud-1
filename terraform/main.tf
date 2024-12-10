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

#   metadata_startup_script = <<EOT
#     #!/bin/bash
#     echo -e '\\033[1;32mWelcome to Cloud-1\\033[0m'
#     echo 'Instance is up and running'
#     echo 'Current user: $(whoami)'
#     echo 'Current directory: $(pwd)'
#     echo 'Instance IP: $(curl -s http://metadata.google.internal/computeMetadata/v1/instance/network-interfaces/0/access-configs/0/external-ip -H "Metadata-Flavor: Google")'
#   EOT

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
  named_port {
	name = "https"
	port = 443
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
	  gcloud compute instances list --format="table(name, networkInterfaces[0].accessConfigs[0].natIP)"
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

resource "google_compute_firewall" "allow_web_traffic" {
  name    = "allow-web-traffic"
  network = google_compute_network.terraform_network.name

  allow {
    protocol = "tcp"
    ports    = ["80","443"]
  }

  source_ranges = ["0.0.0.0/0"]
  target_tags   = ["website"]
}


# #create disk to be shared
# resource "google_compute_disk" "mariadb_disk" {
#   name  = "mariadb-disk"
#   type  = "pd-standard"
#   size  = 10
#   zone  = var.zone
# }

# resource "google_compute_instance" "mariadb_instance" {
#    name         = "mariadb-instance"
#   machine_type = "e2-micro" 
#   zone         = var.zone

#   boot_disk {
#     initialize_params {
#       image = var.os-image
#     }
#   }

#   network_interface {
#     network    = google_compute_network.terraform_network.self_link
#     subnetwork = google_compute_subnetwork.terraform_subnet.self_link
#     access_config {
#       // This block is required to assign an external IP
#     }
#   }

#   attached_disk {
#     source = google_compute_disk.mariadb_disk.id
#     mode   = "READ_WRITE"
#   }

#   metadata_startup_script = <<-EOT
#     #!/bin/bash
#     sudo mkfs.ext4 -F /dev/disk/by-id/google-mariadb-disk
#     sudo mkdir -p /mnt/disks/mariadb
#     sudo mount -o discard,defaults /dev/disk/by-id/google-mariadb-disk /mnt/disks/mariadb
#     sudo mount -o nolock ${google_filestore_instance.mariadb_filestore.networks[0].ip_addresses[0]}:/mariadb_share /mnt/disks/mariadb
#     sudo chmod a+w /mnt/disks/mariadb
#   EOT
# }

# #google cloud filestore to manage shared disk
# resource "google_filestore_instance" "mariadb_filestore" {
#   name       = "mariadb-filestore"
#   tier       = "STANDARD"
#   file_shares {
#     name       = "mariadb_share"
#     capacity_gb = 1024
#   }
#   networks {
#     network = google_compute_network.terraform_network.name
#     modes   = ["MODE_IPV4"]
#   }
# }