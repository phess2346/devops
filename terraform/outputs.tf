# Выходные значения для инфраструктуры

output "идентификатор_кластера_k8s" {
  description = "Идентификатор кластера Kubernetes"
  value       = yandex_kubernetes_cluster.main.id
}

output "внешний_endpoint_кластера_k8s" {
  description = "Внешний endpoint кластера Kubernetes"
  value       = yandex_kubernetes_cluster.main.master[0].external_v4_endpoint
}

output "внутренний_endpoint_кластера_k8s" {
  description = "Внутренний endpoint кластера Kubernetes"
  value       = yandex_kubernetes_cluster.main.master[0].internal_v4_endpoint
}

output "внешний_ip_сервера_srv" {
  description = "Внешний IP адрес сервера srv"
  value       = yandex_compute_instance.srv.network_interface[0].nat_ip_address
}

output "внутренний_ip_сервера_srv" {
  description = "Внутренний IP адрес сервера srv"
  value       = yandex_compute_instance.srv.network_interface[0].ip_address
}

output "идентификатор_сети" {
  description = "Идентификатор созданной сети"
  value       = yandex_vpc_network.main.id
}

output "идентификатор_подсети" {
  description = "Идентификатор созданной подсети"
  value       = yandex_vpc_subnet.subnet-a.id
}

output "идентификатор_группы_безопасности" {
  description = "Идентификатор группы безопасности"
  value       = yandex_vpc_security_group.k8s.id
}

output "версия_kubernetes" {
  description = "Версия Kubernetes кластера"
  value       = yandex_kubernetes_cluster.main.master[0].version
}

output "статус_кластера_k8s" {
  description = "Статус кластера Kubernetes"
  value       = yandex_kubernetes_cluster.main.status
}

output "kubeconfig" {
  description = "Kubeconfig файл для доступа к кластеру"
  value       = <<EOT
apiVersion: v1
clusters:
- cluster:
    certificate-authority-data: ${yandex_kubernetes_cluster.main.master[0].cluster_ca_certificate}
    server: ${yandex_kubernetes_cluster.main.master[0].external_v4_endpoint}
  name: yc-${yandex_kubernetes_cluster.main.name}
contexts:
- context:
    cluster: yc-${yandex_kubernetes_cluster.main.name}
    user: yc-${yandex_kubernetes_cluster.main.name}
  name: yc-${yandex_kubernetes_cluster.main.name}
current-context: yc-${yandex_kubernetes_cluster.main.name}
kind: Config
users:
- name: yc-${yandex_kubernetes_cluster.main.name}
  user:
    exec:
      apiVersion: client.authentication.k8s.io/v1beta1
      command: yc
      args:
      - k8s
      - create-token
EOT
  sensitive = true
}

output "инструкция_доступа_к_кластеру" {
  description = "Инструкция для доступа к кластеру Kubernetes"
  value       = <<EOT

Для доступа к кластеру Kubernetes выполните:

1. Установите yc CLI:
   curl -s https://storage.yandexcloud.net/yandexcloud-yc/install.sh | bash

2. Настройте доступ:
   yc managed-kubernetes cluster get-credentials ${yandex_kubernetes_cluster.main.name} --external

3. Проверьте доступ:
   kubectl get nodes

4. Проверьте pods:
   kubectl get pods --all-namespaces

Доступ к серверу srv:
ssh ubuntu@${yandex_compute_instance.srv.network_interface[0].nat_ip_address}

Доступ к мониторингу:
Grafana: http://${yandex_compute_instance.srv.network_interface[0].nat_ip_address}:3000
Prometheus: http://${yandex_compute_instance.srv.network_interface[0].nat_ip_address}:9090
EOT
}
