.DEFAULT_GOAL: all
all: infrastructure openshift
infrastructure: infrastructure_aws infrastructure_gcp infrastructure_global
destroy_infrastructure: destroy_infrastructure_global destroy_infrastructure_aws destroy_infrastructure_gcp
openshift: admin_password openshift_aws openshift_gcp

infrastructure_aws:
	cd terraform/providers/aws/ca_central_1 && terraform init && terraform apply

infrastructure_gcp:
	cd terraform/providers/gcp/us_east1 && terraform init && terraform apply

infrastructure_global:
	cd terraform/providers/global && terraform init && terraform apply

destroy_infrastructure_aws:
	cd terraform/providers/aws/ca_central_1 && terraform destroy

destroy_infrastructure_gcp:
	cd terraform/providers/gcp/us_east1 && terraform destroy

destroy_infrastructure_global:
	cd terraform/providers/global && terraform destroy

admin_password:
	echo $$(pwgen 16 1) > admin_password
	echo "Admin password: $$(cat admin_password)"

openshift_aws:
	ssh-keyscan -t rsa -H $$(cd terraform/providers/aws/ca_central_1 && terraform output bastion_public_ip) >> ~/.ssh/known_hosts
	ssh -A centos@$$(cd terraform/providers/aws/ca_central_1 && terraform output bastion_public_ip) "ssh-keyscan -t rsa -H $$(cd terraform/providers/aws/ca_central_1 && terraform output master_hostname) >> ~/.ssh/known_hosts"
	ssh -A centos@$$(cd terraform/providers/aws/ca_central_1 && terraform output bastion_public_ip) "ssh-keyscan -t rsa -H $$(cd terraform/providers/aws/ca_central_1 && terraform output node_hostname) >> ~/.ssh/known_hosts"
	scp {terraform/providers/aws/inventory.cfg,ansible/playbooks/prep_origin.yml,ansible/scripts/bastion_install.sh} centos@$$(cd terraform/providers/aws/ca_central_1 && terraform output bastion_public_ip):~
	ssh -A centos@$$(cd terraform/providers/aws/ca_central_1 && terraform output bastion_public_ip) "chmod +x bastion_install.sh && ./bastion_install.sh"
	ssh -A -t centos@$$(cd terraform/providers/aws/ca_central_1 && terraform output bastion_public_ip) ssh $$(cd terraform/providers/aws/ca_central_1 && terraform output master_hostname) "sudo htpasswd -cb /etc/origin/master/htpasswd admin $$(cat admin_password)"
	ssh -A -t centos@$$(cd terraform/providers/aws/ca_central_1 && terraform output bastion_public_ip) ssh $$(cd terraform/providers/aws/ca_central_1 && terraform output master_hostname) "sudo oc adm policy add-cluster-role-to-user cluster-admin admin"

openshift_gcp:
	ssh-keyscan -t rsa -H $$(cd terraform/providers/gcp/us_east1 && terraform output bastion_public_ip) >> ~/.ssh/known_hosts
	ssh -A $$(cd terraform/providers/gcp/us_east1 && terraform output bastion_public_ip) "ssh-keyscan -t rsa -H $$(cd terraform/providers/gcp/us_east1 && terraform output master_hostname) >> ~/.ssh/known_hosts"
	ssh -A $$(cd terraform/providers/gcp/us_east1 && terraform output bastion_public_ip) "ssh-keyscan -t rsa -H $$(cd terraform/providers/gcp/us_east1 && terraform output node_hostname) >> ~/.ssh/known_hosts"
	scp {terraform/providers/gcp/inventory.cfg,ansible/playbooks/prep_origin.yml,ansible/scripts/bastion_install.sh} $$(cd terraform/providers/gcp/us_east1 && terraform output bastion_public_ip):~
	ssh -A $$(cd terraform/providers/gcp/us_east1 && terraform output bastion_public_ip) "chmod +x bastion_install.sh && ./bastion_install.sh"
	ssh -A -t $$(cd terraform/providers/gcp/us_east1 && terraform output bastion_public_ip) ssh $$(cd terraform/providers/gcp/us_east1 && terraform output master_hostname) "sudo htpasswd -cb /etc/origin/master/htpasswd admin $$(cat admin_password)"
	ssh -A -t $$(cd terraform/providers/gcp/us_east1 && terraform output bastion_public_ip) ssh $$(cd terraform/providers/gcp/us_east1 && terraform output master_hostname) "sudo oc adm policy add-cluster-role-to-user cluster-admin admin"
