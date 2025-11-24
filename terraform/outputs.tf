output "k8s_cluster_id" {
  description = "ID Kubernetes кластера"
  value       = yandex_kubernetes_cluster.k8s-cluster.id
}

output "k8s_cluster_external_endpoint" {
  description = "Внешний endpoint кластера Kubernetes"
  value       = yandex_kubernetes_cluster.k8s-cluster.master[0].external_v4_endpoint
}

output "srv_external_ip" {
  description = "Внешний IP адрес сервера srv"
  value       = yandex_compute_instance.srv.network_interface[0].nat_ip_address
}

output "network_id" {
  description = "ID созданной сети"
  value       = yandex_vpc_network.network.id
}

output "subnet_id" {
  description = "ID созданной подсети"
  value       = yandex_vpc_subnet.subnet.id
}

output "security_group_id" {
  description = "ID группы безопасности"
  value       = yandex_vpc_security_group.k8s-sg.id
}

output "service_account_id" {
  description = "ID сервисного аккаунта"
  value       = yandex_iam_service_account.k8s-service-account.id
}

output "access_instructions" {
  description = "Инструкции для доступа к ресурсам"
  value       = <<EOT

Инфраструктура успешно развернута!

Доступ к ресурсам:

1. Kubernetes кластер:
   yc managed-kubernetes cluster get-credentials k8s-cluster --external

2. Сервер srv:
   ssh ubuntu@${yandex_compute_instance.srv.network_interface[0].nat_ip_address}

3. После настройки Ansible будут доступны:
   - Grafana: http://${yandex_compute_instance.srv.network_interface[0].nat_ip_address}:3000
   - Prometheus: http://${yandex_compute_instance.srv.network_interface[0].nat_ip_address}:9090

Для настройки серверов выполните:
cd ansible
./setup-environment.sh

EOT
}
