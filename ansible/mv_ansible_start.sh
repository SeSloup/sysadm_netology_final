#!/bin/bash

# check root
if [ "$EUID" -ne 0 ]
  then echo "Please run as root\n this script acces for ansible user. It creates bastion host ip for ssh."
  exit
fi

## copy folders into main /etc/ansible
DIR=$(pwd)

cp -r $DIR/0_ansible_etc/ /etc/ansible

mkdir -p /etc/ansible/roles
cp -r $DIR/2_ansible_roles/role_diplom_netology /etc/ansible/roles


