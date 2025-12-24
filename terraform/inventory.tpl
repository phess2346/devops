[k8s_master]
k8s-master ansible_host=${k8s_master_ip}

[k8s_worker]
k8s-worker ansible_host=${k8s_worker_ip}

[srv]
srv ansible_host=${srv_ip}

[all:vars]
ansible_user=ubuntu
