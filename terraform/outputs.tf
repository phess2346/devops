output "k8s_master_ip" {
  value = yandex_compute_instance.k8s_master.network_interface[0].nat_ip_address
}

output "k8s_worker_ip" {
  value = yandex_compute_instance.k8s_worker.network_interface[0].nat_ip_address
}

output "srv_ip" {
  value = yandex_compute_instance.srv.network_interface[0].nat_ip_address
}
