# Конфигурация Kubernetes ресурсов

# Дополнительная группа узлов для мониторинга
resource "yandex_kubernetes_node_group" "мониторинг_узлы" {
  cluster_id = yandex_kubernetes_cluster.main.id
  name       = "узлы-мониторинга"
  description = "Группа узлов для развертывания стека мониторинга"

  instance_template {
    platform_id = "standard-v2"

    network_interface {
      nat        = true
      subnet_ids = [yandex_vpc_subnet.subnet-a.id]
      security_group_ids = [yandex_vpc_security_group.k8s.id]
    }

    resources {
      memory = 8
      cores  = 4
    }

    boot_disk {
      type = "network-ssd"
      size = 100
    }

    scheduling_policy {
      preemptible = false
    }

    service_account_id = yandex_iam_service_account.instances.id

    metadata = {
      ssh-keys = "ubuntu:${file(var.ssh_public_key_path)}"
    }
  }

  scale_policy {
    fixed_scale {
      size = 1
    }
  }

  allocation_policy {
    location {
      zone = "ru-central1-a"
    }
  }

  maintenance_policy {
    auto_upgrade = true
    auto_repair  = true
    
    maintenance_window {
      day        = "monday"
      start_time = "23:00"
      duration   = "3h"
    }
  }
}

# Создание namespace для мониторинга
resource "kubernetes_namespace" "мониторинг" {
  metadata {
    name = "мониторинг"
    labels = {
      name = "мониторинг"
    }
  }

  depends_on = [yandex_kubernetes_cluster.main]
}

# Создание namespace для приложений
resource "kubernetes_namespace" "приложения" {
  metadata {
    name = "приложения"
    labels = {
      name = "приложения"
    }
  }

  depends_on = [yandex_kubernetes_cluster.main]
}

# Service Account для приложений
resource "kubernetes_service_account" "приложения_sa" {
  metadata {
    name      = "приложения-service-account"
    namespace = kubernetes_namespace.приложения.metadata[0].name
  }

  depends_on = [yandex_kubernetes_cluster.main]
}

# ConfigMap для базовых настроек
resource "kubernetes_config_map" "базовые_настройки" {
  metadata {
    name      = "базовые-настройки"
    namespace = "kube-system"
  }

  data = {
    "cluster-name" = yandex_kubernetes_cluster.main.name
    "cloud-region" = "ru-central1"
  }

  depends_on = [yandex_kubernetes_cluster.main]
}

# Storage Class для SSD
resource "kubernetes_storage_class" "ssd" {
  metadata {
    name = "ssd"
  }

  storage_provisioner = "yandex.cloud/disk-csi-driver"
  reclaim_policy      = "Retain"
  volume_binding_mode = "Immediate"

  parameters = {
    type = "network-ssd"
  }

  depends_on = [yandex_kubernetes_cluster.main]
}

# Storage Class для HDD
resource "kubernetes_storage_class" "hdd" {
  metadata {
    name = "hdd"
  }

  storage_provisioner = "yandex.cloud/disk-csi-driver"
  reclaim_policy      = "Retain"
  volume_binding_mode = "Immediate"

  parameters = {
    type = "network-hdd"
  }

  depends_on = [yandex_kubernetes_cluster.main]
}

# Resource Quota для namespace приложений
resource "kubernetes_resource_quota" "лимиты_приложений" {
  metadata {
    name      = "лимиты-приложений"
    namespace = kubernetes_namespace.приложения.metadata[0].name
  }

  spec {
    hard = {
      "requests.cpu"    = "4"
      "requests.memory" = "8Gi"
      "limits.cpu"      = "8"
      "limits.memory"   = "16Gi"
      "pods"            = "20"
      "services"        = "10"
    }
  }

  depends_on = [yandex_kubernetes_cluster.main]
}

# Limit Range для namespace приложений
resource "kubernetes_limit_range" "ограничения_приложений" {
  metadata {
    name      = "ограничения-приложений"
    namespace = kubernetes_namespace.приложения.metadata[0].name
  }

  spec {
    limit {
      type = "Container"

      default_request = {
        cpu    = "100m"
        memory = "128Mi"
      }

      default = {
        cpu    = "500m"
        memory = "512Mi"
      }

      max = {
        cpu    = "2"
        memory = "2Gi"
      }
    }
  }

  depends_on = [yandex_kubernetes_cluster.main]
}

# Сетевые политики
resource "kubernetes_network_policy" "базовая_политика" {
  metadata {
    name      = "базовая-сетевая-политика"
    namespace = kubernetes_namespace.приложения.metadata[0].name
  }

  spec {
    pod_selector {}
    policy_types = ["Ingress"]

    ingress {
      from {
        namespace_selector {
          match_labels = {
            name = kubernetes_namespace.приложения.metadata[0].name
          }
        }
      }

      from {
        ip_block {
          cidr = "0.0.0.0/0"
        }
      }
    }
  }

  depends_on = [yandex_kubernetes_cluster.main]
}

# Secret для базовой аутентификации
resource "kubernetes_secret" "базовые_секреты" {
  metadata {
    name      = "базовые-секреты"
    namespace = "default"
  }

  data = {
    "cluster-domain" = "cluster.local"
  }

  type = "Opaque"

  depends_on = [yandex_kubernetes_cluster.main]
}

# Provider Kubernetes
provider "kubernetes" {
  host                   = yandex_kubernetes_cluster.main.master[0].external_v4_endpoint
  cluster_ca_certificate = base64decode(yandex_kubernetes_cluster.main.master[0].cluster_ca_certificate)
  token                  = data.yandex_client_config.client.iam_token
}

# Data source для клиентской конфигурации
data "yandex_client_config" "client" {}
