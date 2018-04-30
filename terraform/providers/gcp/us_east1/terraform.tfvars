#--------------------------------------------------------------
# General
#--------------------------------------------------------------

name                    = "openshiftdemo"
cluster_id              = "openshiftdemo-gcp"
region                  = "us-east1"
zone                    = "us-east1-b"
ssh_key_name            = "stuart"

#--------------------------------------------------------------
# Network
#--------------------------------------------------------------

vpc_cidr        = "10.1.0.0/16"
az              = "ca-central-1a"
allowed_cidrs   = "0.0.0.0/0"

#--------------------------------------------------------------
# Compute
#--------------------------------------------------------------

machine_image           = "centos-cloud/centos-7"
openshift_machine_type  = "n1-standard-2"
bastion_machine_type    = "n1-standard-1"
