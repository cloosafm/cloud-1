output "webapp_URL" {
  value = "http://${google_compute_instance.my_instance.network_interface.0.access_config.0.nat_ip}"
}