# Дополнительные настройки Kubernetes

# Группа узлов для приложений
resource "yandex_kubernetes_node_group" "app_nodes" {
  cluster_id = yandex_kubernetes_cluster.k8s-cluster.id
  name       = "app-nodes"
  version    = "1.25"

  instance_template {
    platform_id = "standard-v2"

    network_interface {
      nat        = true
      subnet_ids = [yandex_vpc_subnet.subnet.id]
      security_group_ids = [yandex_vpc_security_group.k8s-sg.id]
    }

    resources {
      memory = 4
      cores  = 2
    }

    boot_disk {
      type = "network-ssd"
      size = 64
    }

    scheduling_policy {
      preemptible = false
    }

    metadata = {
      ssh-keys = "ubuntu:${file(var.ssh_public_key)}"
    }
  }

  scale_policy {
    fixed_scale {
      size = 2
    }
  }

  allocation_policy {
    location {
      zone = var.zone
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

# Дополнительная группа узлов для мониторинга
resource "yandex_kubernetes_node_group" "monitoring_nodes" {
  cluster_id = yandex_kubernetes_cluster.k8s-cluster.id
  name       = "monitoring-nodes"
  version    = "1.25"

  instance_template {
    platform_id = "standard-v2"

    network_interface {
      nat        = true
      subnet_ids = [yandex_vpc_subnet.subnet.id]
      security_group_ids = [yandex_vpc_security_group.k8s-sg.id]
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

    metadata = {
      ssh-keys = "ubuntu:${file(var.ssh_public_key)}"
    }
  }

  scale_policy {
    fixed_scale {
      size = 1
    }
  }

  allocation_policy {
    location {
      zone = var.zone
    }
  }
}
