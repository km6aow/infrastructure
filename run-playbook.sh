#!/bin/bash
PLAYBOOK=${1-provision-host.yml}
export ANSIBLE_CONFIG=ansible-vm.cfg
export ANSIBLE_PYTHON_INTERPRETER=/usr/bin/python3
export LC_ALL="en_US.UTF-8"
export LC_CTYPE="en_US.UTF-8"
export CI=true
ansible-playbook -v -u aredn \
    --extra-vars="{ \
      \"ANSIBLE_AREDN_PASSWORD\": \"${ANSIBLE_AREDN_PASSWORD}\", \
      \"ANSIBLE_GITHUB_TOKEN\": \"${ANSIBLE_GITHUB_TOKEN}\", \
      \"ANSIBLE_VAULT_ADDR\": \"${VAULT_ADDR}\", \
      \"ANSIBLE_VAULT_TOKEN\": \"${VAULT_TOKEN}\", \
      \"CONCOURSE_DATABASE_PASSWORD\": \"${CONCOURSE_DATABASE_PASSWORD}\", \
      \"CONCOURSE_VAULT_TOKEN\": \"${CONCOURSE_VAULT_TOKEN}\", \
      \"GRAFANA_ADMIN_PASSWORD\": \"${GRAFANA_ADMIN_PASSWORD}\" \
      }" \
    --limit=ubuntu-vm.dis.com \
    --private-key=ssh/ansible_rsa \
    --inventory inventory/vm.yml \
    ${PLAYBOOK}
