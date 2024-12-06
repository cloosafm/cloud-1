# output "webapp_URL" {
#   value = "http://${google_compute_instance.my_instance.network_interface.0.access_config.0.nat_ip}"
# }

# output "mig_name" {
#   value = google_compute_instance_group_manager.my_instance_group.name
#   description = "The name of the Managed Instance Group"
# }