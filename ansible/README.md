# Автоматизация развертывания с Ansible

## Описание

Этот проект содержит Ansible плейбуки и роли для автоматизации настройки серверов и развертывания приложений.

## Структура проекта

ansible/
├── inventory/           # Файлы инвентаря
│   └── group_vars/     # Переменные групп
├── playbooks/          # Плейбуки для различных задач
├── roles/              # Роли для многократного использования
├── vars/               # Файлы переменных
├── ansible.cfg         # Конфигурация Ansible
└── README.md           # Этот файл

1. Подготовка инвентаря

cd ansible
cp inventory/production.template inventory/production
# Отредактируйте inventory/production с реальными IP-адресами

2. Подготовка переменных

cp vars/secrets.yml.example vars/secrets.yml
# Отредактируйте vars/secrets.yml с реальными значениями

3. Запуск плейбуков

# Настроить сервер srv
ansible-playbook playbooks/srv-settings.yml

# Настроить узлы Kubernetes
ansible-playbook playbooks/k8s-settings.yml

# Развернуть мониторинг
ansible-playbook playbooks/monitoring-settings.yml

# Настроить CI/CD
ansible-playbook playbooks/CICD-settings.yml

# Обновить систему
ansible-playbook playbooks/update-system.yml

Подробное описание плейбуков
srv-settings.yml
Настройка базовой системы
Установка Docker и Docker Compose
Развертывание стека мониторинга (Prometheus, Grafana, Node Exporter)
Установка kubectl и yc CLI
Настройка фаервола

k8s-settings.yml
Подготовка узлов Kubernetes
Установка kubeadm, kubelet, kubectl
Настройка системных параметров
Конфигурация сети

monitoring-settings.yml
Развертывание Prometheus Stack в Kubernetes
Настройка Grafana с дашбордами
Конфигурация алертинга
Настройка сбора метрик

CICD-settings.yml
Установка GitLab Runner
Настройка пользователя для CI/CD
Создание рабочих каталогов
Конфигурация доступа

update-system.yml
Обновление системных пакетов
Очистка временных файлов
Управление перезагрузкой

Требования
Ansible >= 2.9
Python 3
SSH доступ к целевым серверам

Настройка инвентаря
Файл inventory/production должен содержать реальные IP-адреса:

ini
[srv_servers]
srv ansible_host=1.2.3.4 ansible_user=ubuntu

[k8s_master]
master ansible_host=5.6.7.8 ansible_user=ubuntu

[k8s_nodes]
node-1 ansible_host=9.10.11.12 ansible_user=ubuntu
node-2 ansible_host=13.14.15.16 ansible_user=ubuntu
Настройка переменных
В файле vars/secrets.yml укажите:

grafana_admin_password: "ваш_сильный_пароль"
gitlab_runner_token: "ваш_runner_токен"
ssh_public_keys:
  - "ваш_ssh_публичный_ключ"


Полезные команды
# Проверить подключение
ansible all -m ping

# Запустить с тегами
ansible-playbook playbooks/srv-settings.yml --tags "docker,monitoring"

# Проверить синтаксис
ansible-playbook playbooks/srv-settings.yml --syntax-check

# Запустить в режиме проверки
ansible-playbook playbooks/srv-settings.yml --check

Порядок развертывания
1.Сначала запустите Terraform для создания инфраструктуры
2.Обновите IP-адреса в инвентаре Ansible
3.Запустите плейбуки в следующем порядке:

srv-settings.yml
k8s-settings.yml
monitoring-settings.yml
CICD-settings.yml
