#!/bin/bash

#./terraform apply -var-file=./secret.tfvars -var-file=./variables_params.tfvars
./terraform output > ./file_nat_ip.txt
chmod 777 ./file_nat_ip.txt





