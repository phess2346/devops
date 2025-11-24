terraform {
  required_version = ">= 1.0"
  required_providers {
    yandex = {
      source  = "yandex-cloud/yandex"
      version = "~> 0.80"
    }
  }
  backend "s3" {
    endpoint   = "storage.yandexcloud.net"
    bucket     = "terraform-state-bucket"
    region     = "ru-central1"
    key        = "terraform.tfstate"
    access_key = var.yc_access_key
    secret_key = var.yc_secret_key
    skip_region_validation      = true
    skip_credentials_validation = true
  }
}

provider "yandex" {
  zone      = "ru-central1-a"
  token     = var.yc_token
  cloud_id  = var.yc_cloud_id
  folder_id = var.yc_folder_id
}

# Создание сервисного аккаунта для Kubernetes
resource "yandex_iam_service_account" "k8s" {
  name        = "k8s-service-account"
  description = "Service account for Kubernetes cluster"
}

# Назначение ролей сервисному аккаунту
resource "yandex_resourcemanager_folder_iam_member" "k8s_roles" {
  for_each = toset([
    "editor",
    "container-registry.images.puller",
    "container-registry.images.pusher"
  ])
  
  folder_id = var.yc_folder_id
  role      = each.key
  member    = "serviceAccount:${yandex_iam_service_account.k8s.id}"
}

# Создание сервисного аккаунта для инстансов
resource "yandex_iam_service_account" "instances" {
  name        = "instances-service-account"
  description = "Service account for VM instances"
}

# Сеть и подсети
resource "yandex_vpc_network" "main" {
  name = "main-network"
}

resource "yandex_vpc_subnet" "subnet-a" {
  name           = "subnet-a"
  zone           = "ru-central1-a"
  network_id     = yandex_vpc_network.main.id
  v4_cidr_blocks = ["192.168.10.0/24"]
}

# Security Group для Kubernetes
resource "yandex_vpc_security_group" "k8s" {
  name        = "k8s-security-group"
  network_id  = yandex_vpc_network.main.id

  ingress {
    protocol       = "TCP"
    description    = "Kubernetes API"
    port           = 6443
    v4_cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    protocol       = "TCP"
    description    = "SSH"
    port           = 22
    v4_cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    protocol       = "TCP"
    description    = "HTTP"
    port           = 80
    v4_cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    protocol       = "TCP"
    description    = "HTTPS"
    port           = 443
    v4_cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    protocol       = "ANY"
    description    = "Outgoing traffic"
    v4_cidr_blocks = ["0.0.0.0/0"]
  }
}

# Kubernetes кластер
resource "yandex_kubernetes_cluster" "main" {
  name        = "main-cluster"
  description = "Main Kubernetes cluster"

  network_id = yandex_vpc_network.main.id

  master {
    version = "1.25"
    zonal {
      zone      = yandex_vpc_subnet.subnet-a.zone
      subnet_id = yandex_vpc_subnet.subnet-a.id
    }

    public_address = true
    security_group_ids = [yandex_vpc_security_group.k8s.id]
  }

  service_account_id      = yandex_iam_service_account.k8s.id
  node_service_account_id = yandex_iam_service_account.k8s.id

  depends_on = [
    yandex_resourcemanager_folder_iam_member.k8s_roles
  ]
}

# Node Group для приложений
resource "yandex_kubernetes_node_group" "app" {
  cluster_id = yandex_kubernetes_cluster.main.id
  name       = "app-nodes"

  instance_template {
    platform_id = "standard-v2"

    network_interface {
      nat        = true
      subnet_ids = [yandex_vpc_subnet.subnet-a.id]
      security_group_ids = [yandex_vpc_security_group.k8s.id]
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

    service_account_id = yandex_iam_service_account.instances.id
  }

  scale_policy {
    fixed_scale {
      size = 1
    }
  }
}

# Сервер srv для инструментов
resource "yandex_compute_instance" "srv" {
  name        = "srv"
  platform_id = "standard-v2"
  zone        = "ru-central1-a"

  resources {
    cores  = 4
    memory = 8
  }

  boot_disk {
    initialize_params {
      image_id = "fd827b91d99psvq5fjit" # Ubuntu 22.04
      size     = 50
      type     = "network-ssd"
    }
  }

  network_interface {
    subnet_id = yandex_vpc_subnet.subnet-a.id
    nat       = true
    security_group_ids = [yandex_vpc_security_group.k8s.id]
  }

  metadata = {
    ssh-keys = "ubuntu:${file("~/.ssh/id_rsa.pub")}"
  }

  scheduling_policy {
    preemptible = false
  }

  service_account_id = yandex_iam_service_account.instances.id
}

# Output values
output "k8s_cluster_id" {
  value = yandex_kubernetes_cluster.main.id
}

output "k8s_cluster_external_endpoint" {
  value = yandex_kubernetes_cluster.main.master[0].external_v4_endpoint
}

output "srv_external_ip" {
  value = yandex_compute_instance.srv.network_interface[0].nat_ip_address
}

output "kubeconfig" {
  value     = <<EOT
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
