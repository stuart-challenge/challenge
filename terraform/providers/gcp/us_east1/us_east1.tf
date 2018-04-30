variable "region"               { }
variable "zone"                 { }
variable "cluster_id"           { }
variable "ssh_key_name"         { }
variable "vpc_cidr"             { }
variable "allowed_cidrs"        { }

variable "machine_image"            { }
variable "openshift_machine_type"   { }
variable "bastion_machine_type"     { }


provider "google" {
  region    = "${var.region}"
  project   = "${var.project}"
}

module "network" {
  source = "../../../modules/gcp/network"

  region        = "${var.region}"
  vpc_cidr      = "${var.vpc_cidr}"
  allowed_cidrs = "${var.allowed_cidrs}"
  admin_cidrs   = "${var.admin_cidrs}"
}

module "dns" {
  source = "../../../modules/gcp/dns"

  zone_name         = "${var.zone_name}"
  master_ip         = "${module.compute.master_ip}"
  master_public_ip  = "${module.compute.master_public_ip}"
  router_ip         = "${module.compute.router_ip}"
  node_ip           = "${module.compute.node_ip}"
}

module "cloudflare" {
  source = "../../../modules/cloudflare/dns"

  cloudflare_email  = "${var.cloudflare_email}"
  cloudflare_token  = "${var.cloudflare_token}"
  name              = "gcp"
  zone_name         = "${var.cloudflare_zone_name}"
  nameservers       = "${module.dns.nameservers}"
}

module "compute" {
  source = "../../../modules/gcp/compute"

  zone                      = "${var.zone}"
  ssh_key_name              = "${var.ssh_key_name}"
  ssh_public_key            = "${var.ssh_public_key}"
  public_network            = "${module.network.public_subnetwork_self_link}"
  private_network           = "${module.network.private_subnetwork_self_link}"
  public_subnet_cidr        = "${module.network.public_subnet_cidr}"
  private_subnet_cidr       = "${module.network.private_subnet_cidr}"
  admin_cidrs               = "${var.admin_cidrs}"
  machine_image             = "${var.machine_image}"
  openshift_machine_type    = "${var.openshift_machine_type}"
  bastion_machine_type      = "${var.bastion_machine_type}"
}

module "inventory" {
  source = "../../../modules/gcp/util/inventory"

  project                 = "${var.project}"
  cluster_id              = "${var.cluster_id}"
  master_public_hostname  = "${module.dns.master_api_hostname}"
  router_hostname         = "${module.dns.router_hostname}"
  master_name             = "${module.compute.master_name}"
  node_name               = "${module.compute.node_name}"
}

output "project" { value = "${var.project}" }
output "region" { value = "${var.region}" }
output "network_self_link" { value = "${module.network.network_self_link}" }
output "public_subnet_cidr" { value = "${module.network.public_subnet_cidr}" }
output "private_subnet_cidr" { value = "${module.network.private_subnet_cidr}" }
output "bastion_public_ip" { value = "${module.compute.bastion_public_ip}" }
output "master_hostname" { value = "${module.compute.master_name}" }
output "node_hostname" { value = "${module.compute.node_name}" }
