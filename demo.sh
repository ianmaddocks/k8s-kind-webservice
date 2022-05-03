#!/usr/bin/env sh

set -e
terraform init
terraform plan
terraform apply -auto-approve || true
sleep 1
terraform apply -auto-approve

sleep 2
printf "\nYou should see '/version' as a reponse below:\n"
curl http://localhost/version