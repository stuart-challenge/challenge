variable "region"               { }
variable "ssh_key_name"         { }
variable "name"                 { }
variable "cluster_id"           { }
variable "vpc_cidr"             { }
variable "az"                   { }
variable "allowed_cidrs"        { }

variable "openshift_ami"           { }
variable "openshift_instance_type" { }
variable "bastion_ami"             { }
variable "bastion_instance_type"   { }


provider "aws" {
  region = "${var.region}"
}

resource "aws_key_pair" "operator_key" {
  key_name   = "${var.ssh_key_name}"
  public_key = "${var.ssh_public_key}"

  lifecycle { create_before_destroy = true }
}

module "iam" {
  source = "../../../modules/aws/util/iam"
}

module "dns" {
  source = "../../../modules/aws/dns"

  zone_name       = "${var.zone_name}"
  master_api_name = "${module.compute.master_public_hostname}"
  master_zone_id  = "${module.compute.master_public_zone_id}"
  router_name     = "${module.compute.router_public_hostname}"
  router_zone_id  = "${module.compute.router_public_zone_id}"
  master_ip       = "${module.compute.master_ip}"
  node_ip         = "${module.compute.node_ip}"
}

module "cloudflare" {
  source = "../../../modules/cloudflare/dns"

  cloudflare_email  = "${var.cloudflare_email}"
  cloudflare_token  = "${var.cloudflare_token}"
  name              = "aws"
  zone_name         = "${var.cloudflare_zone_name}"
  nameservers       = "${module.dns.nameservers}"
}

module "certificate" {
  source = "../../../modules/aws/certificate"

  zone_id         = "${module.dns.zone_id}"
  zone_name       = "${var.zone_name}"
}

module "network" {
  source = "../../../modules/aws/network"

  name        = "${var.name}"
  cluster_id  = "${var.cluster_id}"
  vpc_cidr    = "${var.vpc_cidr}"
  az          = "${var.az}"
}

module "compute" {
  source = "../../../modules/aws/compute"

  name                          = "${var.name}"
  cluster_id                    = "${var.cluster_id}"
  region                        = "${var.region}"
  az                            = "${var.az}"
  vpc_id                        = "${module.network.vpc_id}"
  vpc_cidr                      = "${var.vpc_cidr}"
  vpc_default_security_group_id = "${module.network.vpc_default_security_group_id}"
  public_subnet_id              = "${module.network.public_subnet_id}"
  private_subnet_id             = "${module.network.private_subnet_id}"
  instance_profile_id           = "${module.iam.instance_profile_id}"
  ssh_key_name                  = "${var.ssh_key_name}"
  allowed_cidrs                 = "${var.allowed_cidrs}"
  admin_cidrs                   = "${var.admin_cidrs}"

  openshift_ami             = "${var.openshift_ami}"
  openshift_instance_type   = "${var.openshift_instance_type}"
  bastion_ami               = "${var.bastion_ami}"
  bastion_instance_type     = "${var.bastion_instance_type}"
  certificate_arn           = "${module.certificate.certificate_arn}"
}

module "inventory" {
  source = "../../../modules/aws/util/inventory"

  cluster_id              = "${var.cluster_id}"
  access_key              = "${module.iam.iam_access_key}"
  secret_key              = "${module.iam.iam_secret_key}"
  master_public_hostname  = "${module.dns.master_api_hostname}"
  router_hostname         = "${module.dns.router_hostname}"
  master_hostname         = "${module.compute.master_hostname}"
  node_hostname           = "${module.compute.node_hostname}"
}

output "region" { value = "${var.region}" }
output "vpc_id" { value = "${module.network.vpc_id}" }
output "igw_id" { value = "${module.network.igw_id}" }
output "public_route_table_id" { value = "${module.network.public_route_table_id}" }
output "private_route_table_id" { value = "${module.network.private_route_table_id}" }
output "default_security_group_id" { value = "${module.network.vpc_default_security_group_id}" }
output "public_subnet_cidr" { value = "${module.network.public_subnet_cidr}" }
output "private_subnet_cidr" { value = "${module.network.private_subnet_cidr}" }
output "bastion_public_ip" { value = "${module.compute.bastion_public_ip}" }
output "master_public_hostname" { value = "${module.dns.master_api_hostname}" }
output "master_hostname" { value = "${module.compute.master_hostname}" }
output "node_hostname" { value = "${module.compute.node_hostname}" }
