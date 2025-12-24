terraform {
  required_version = ">= 1.5"

  required_providers {
    yandex = {
      source  = "yandex-cloud/yandex"
      version = "~> 0.100"
    }
    local = {
      source  = "hashicorp/local"
      version = "~> 2.4"
    }
  }
}
