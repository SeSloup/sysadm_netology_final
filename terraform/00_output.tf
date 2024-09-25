output "external_ip_address_nat_instance" {
  value = yandex_compute_instance.nat-instance.network_interface.0.nat_ip_address
}