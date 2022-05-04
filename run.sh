#!/usr/bin/env bash
terraform init -upgrade && terraform plan && terraform apply -auto-approve 