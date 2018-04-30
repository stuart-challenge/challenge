#--------------------------------------------------------------
# General
#--------------------------------------------------------------

name                    = "openshiftdemo"
cluster_id              = "openshiftdemo-aws"
region                  = "ca-central-1"
ssh_key_name            = "stuart"

#--------------------------------------------------------------
# Network
#--------------------------------------------------------------

vpc_cidr        = "10.0.0.0/16"
az              = "ca-central-1a"
allowed_cidrs   = "0.0.0.0/0"

#--------------------------------------------------------------
# Compute
#--------------------------------------------------------------

openshift_instance_type = "t2.large"
openshift_ami           = "ami-dcad28b8"
bastion_instance_type   = "t2.micro"
bastion_ami             = "ami-dcad28b8"
