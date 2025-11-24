# Инфраструктура как код с Terraform

## Описание проекта

Этот проект описывает инфраструктуру для развертывания Kubernetes кластера и сервера инструментов в Yandex Cloud.

## Архитектура

- **Kubernetes кластер**: Управляемый кластер с мастер узлом и узлами приложений
- **Сервер srv**: Сервер для мониторинга, логгирования и CI/CD инструментов
- **Сеть**: Изолированная сеть с группами безопасности

## Предварительные требования

### 1. Установка необходимых инструментов

```bash
# Установка Terraform
wget -O- https://apt.releases.hashicorp.com/gpg | gpg --dearmor | sudo tee /usr/share/keyrings/hashicorp-archive-keyring.gpg
echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/hashicorp.list
sudo apt update && sudo apt install terraform

# Установка Yandex Cloud CLI
curl -s https://storage.yandexcloud.net/yandexcloud-yc/install.sh | bash
source ~/.bashrc
