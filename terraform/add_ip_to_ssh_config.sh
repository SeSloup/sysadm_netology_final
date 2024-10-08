#!/bin/bash
if [ "$EUID" -ne 0 ]
  then echo "Please run as root\n this script acces for ansible user. It creates bastion host ip for ssh."
  exit
fi

DIPLOMFOLDER=$(pwd)

USERansible="gekasologub"


eval "IP=\"$(cat ${DIPLOMFOLDER}/file_nat_ip.txt | grep "external_ip_address_nat_instance" | tr -d ' ')\""

echo $IP

eval $IP

echo $(whoami)
echo $external_ip_address_nat_instance

sed -i '/Host bastion_netology/,/HostName \(\(25\[0-5\]\|\(2\[0-4\]\|1\\d\|\[1-9\]\|\)\\d\)\\.\?\\b\)\{4\}\$/d' /home/${USERansible}//.ssh/config

echo "Host bastion_netology
    HostName $external_ip_address_nat_instance" > /home/${USERansible}/.ssh/config
    
chown ${USERansible}:${USERansible} /home/${USERansible}/.ssh/config


echo "$(cat /home/${USERansible}/.ssh/config)"
