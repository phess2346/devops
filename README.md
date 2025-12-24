# DevOps Infrastructure (Terraform + Ansible)

## Описание проекта

Данный репозиторий содержит описание инфраструктуры в виде кода (IaC) для учебного проекта.

Инфраструктура разворачивается в **Yandex Cloud** и включает:
- Kubernetes-кластер (1 master + 1 worker) на базе kubeadm
- Служебный сервер `srv` с простым мониторингом (Prometheus + node_exporter)
- Полную автоматизацию с использованием **Terraform** и **Ansible**

---

## Архитектура

- **k8s-master**
  - Control Plane Kubernetes
- **k8s-worker**
  - Worker-нода Kubernetes
- **srv**
  - Docker
  - Prometheus
  - node_exporter

Все серверы создаются как Compute Instances в одной VPC и одной subnet.

---

## Используемые технологии

- Yandex Cloud
- Terraform
- Ansible
- Kubernetes (kubeadm)
- Docker / docker-compose
- Prometheus

---

## Требования

На локальной машине должны быть установлены:
- Terraform >= 1.5
- Ansible >= 2.15
- Yandex Cloud CLI
- SSH-ключ (public key)

---

## Структура репозитория

```text
devops/
├── terraform/
│   ├── main.tf
│   ├── providers.tf
│   ├── variables.tf
│   ├── outputs.tf
│   ├── versions.tf
│   └── inventory.tpl
│
├── ansible/
│   ├── inventory.ini       
│   ├── playbook.yml
│   └── roles/
│       ├── common/
│       ├── docker/
│       ├── k8s-common/
│       ├── k8s-master/
│       ├── k8s-worker/
│       └── monitoring/
│
├── .gitignore
└── README.md


Развертывание инфраструктуры
1. Инициализация Terraform
cd terraform
terraform init

2. Применение Terraform
terraform apply


Во время выполнения Terraform запросит:

1. cloud_id

2. folder_id

3. ssh_public_key

После успешного применения:

1. будут созданы все виртуальные машины;

2. автоматически сгенерируется файл ansible/inventory.ini.

3. Настройка серверов (Ansible)

После завершения Terraform:

cd ../ansible
ansible-playbook -i inventory.ini playbook.yml


Ansible автоматически:

1. установит Docker на все серверы;

2. развернет Kubernetes кластер (master + worker);

3. поднимет мониторинг на сервере srv.

Проверка Kubernetes

1. Подключиться к master-ноде:

ssh ubuntu@<k8s_master_ip>


2. Проверить состояние кластера:

kubectl get nodes


Ожидаемый результат:

master — Ready

worker — Ready

Мониторинг

На сервере srv разворачивается Prometheus.

Доступ к веб-интерфейсу:

http://<srv_ip>:9090
