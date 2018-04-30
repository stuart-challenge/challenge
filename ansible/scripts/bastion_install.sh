#!/bin/bash
set -euxo pipefail

sudo yum install -y epel-release
sudo yum install -y ansible git
ansible-playbook -i ./inventory.cfg ./prep_origin.yml

if [ ! -d "openshift-ansible" ]; then
    git clone -b release-3.9 https://github.com/openshift/openshift-ansible
fi

ansible-playbook -i ./inventory.cfg ./openshift-ansible/playbooks/prerequisites.yml
ansible-playbook -i ./inventory.cfg ./openshift-ansible/playbooks/deploy_cluster.yml
