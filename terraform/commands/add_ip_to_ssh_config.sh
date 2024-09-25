#!/bin/bash
DIPLOMFOLDER="/home/eugene/Documents/Trash_virtual_machines/Диплом"

USERansible="gekasologub"

echo "this script acces for ansible user. It creates bastion host ip for ssh. for enable you need be root"

IP="$(cat ${DIPLOMFOLDER}/terraform/file_nat_ip.txt | tr -d ' ')"

eval $IP

echo $(whoami)

sed -i '/Host bastion_netology/,/HostName \(\(25\[0-5\]\|\(2\[0-4\]\|1\\d\|\[1-9\]\|\)\\d\)\\.\?\\b\)\{4\}\$/d' /home/${USERansible}//.ssh/config

echo "Host bastion_netology
    HostName $external_ip_address_vm_1" > /home/${USERansible}/.ssh/config
    
chown ${USERansible}:${USERansible} /home/${USERansible}/.ssh/config
