variable "yc_token" {
  type        = string
  description = "Yandex Cloud OAuth token"
  sensitive   = true
}

variable "yc_cloud_id" {
  type        = string
  description = "Yandex Cloud ID"
  sensitive   = true
}

variable "yc_folder_id" {
  type        = string
  description = "Yandex Cloud Folder ID"
  sensitive   = true
}

variable "yc_access_key" {
  type        = string
  description = "Yandex Cloud Storage access key for terraform backend"
  sensitive   = true
}

variable "yc_secret_key" {
  type        = string
  description = "Yandex Cloud Storage secret key for terraform backend"
  sensitive   = true
}

variable "ssh_public_key_path" {
  type        = string
  description = "Path to SSH public key"
  default     = "~/.ssh/id_rsa.pub"
}
