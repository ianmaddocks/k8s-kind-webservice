#!/usr/bin/env sh

set -e
terraform init
terraform plan
terraform apply -auto-approve || true
sleep 1
terraform apply -auto-approve

kubectl apply -f ./postgres

sleep 2
printf "\nYou should see '/info' as a reponse below:\n"
curl http://localhost/info