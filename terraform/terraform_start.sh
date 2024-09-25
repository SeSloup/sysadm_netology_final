#!/bin/bash
#commands

for host_name in "vm-kibana" "vm-elk" "vm-zabbix" "vm-nginx-1" "vm-nginx-2"
do
 ssh-keygen -f "/home/gekasologub/.ssh/known_hosts" -R $host_name".ru-central1.internal"
done

./terraform init
./terraform apply -var-file=./secret.tfvars -var-file=./variables_params.tfvars
./terraform output > ./file_nat_ip.txt
chmod 777 ./file_nat_ip.txt

./add_ip_to_ssh_config.sh










