output "external_ip_address_nat_instance" {
  value = yandex_compute_instance.nat-instance.network_interface.0.nat_ip_address
}

output "external_ip_address_vm_kibana" {
  value = yandex_compute_instance.vm-kibana.network_interface.0.nat_ip_address
}

output "external_ip_address_vm_zabbix" {
  value = yandex_compute_instance.vm-zabbix.network_interface.0.nat_ip_address
}

output "external_ip_address_alb_load_balancer" {
  value = yandex_alb_load_balancer.alb-1.listener[0].endpoint[0].address[0].external_ipv4_address[0].address
}

