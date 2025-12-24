resource "yandex_vpc_network" "main" {
  name = "main-network"
}

resource "yandex_vpc_subnet" "public" {
  name           = "public-subnet"
  zone           = var.zone
  network_id     = yandex_vpc_network.main.id
  v4_cidr_blocks = ["10.0.0.0/24"]
}

locals {
  image_id = data.yandex_compute_image.ubuntu.id
}

resource "yandex_compute_instance" "k8s_master" {
  name = "k8s-master"

  resources {
    cores  = 2
    memory = 4
  }

  boot_disk {
    initialize_params {
      image_id = local.image_id
    }
  }

  network_interface {
    subnet_id = yandex_vpc_subnet.public.id
    nat       = true
  }

  metadata = {
    ssh-keys = "ubuntu:${var.ssh_public_key}"
  }
}

resource "yandex_compute_instance" "k8s_worker" {
  name = "k8s-worker"

  resources {
    cores  = 2
    memory = 4
  }

  boot_disk {
    initialize_params {
      image_id = local.image_id
    }
  }

  network_interface {
    subnet_id = yandex_vpc_subnet.public.id
    nat       = true
  }

  metadata = {
    ssh-keys = "ubuntu:${var.ssh_public_key}"
  }
}

resource "yandex_compute_instance" "srv" {
  name = "srv"

  resources {
    cores  = 2
    memory = 4
  }

  boot_disk {
    initialize_params {
      image_id = local.image_id
    }
  }

  network_interface {
    subnet_id = yandex_vpc_subnet.public.id
    nat       = true
  }

  metadata = {
    ssh-keys = "ubuntu:${var.ssh_public_key}"
  }
}

resource "local_file" "ansible_inventory" {
  filename = "../ansible/inventory.ini"

  content = templatefile("${path.module}/inventory.tpl", {
    k8s_master_ip = yandex_compute_instance.k8s_master.network_interface[0].nat_ip_address
    k8s_worker_ip = yandex_compute_instance.k8s_worker.network_interface[0].nat_ip_address
    srv_ip        = yandex_compute_instance.srv.network_interface[0].nat_ip_address
  })
}
