data "terraform_remote_state" "aws" {
  backend = "local"

  config {
    path = "../aws/ca_central_1/terraform.tfstate"
  }
}

data "terraform_remote_state" "google" {
  backend = "local"

  config {
    path = "../gcp/us_east1/terraform.tfstate"
  }
}

provider "google" {
  region    = "${data.terraform_remote_state.google.region}"
  project   = "${data.terraform_remote_state.google.project}"
}

provider "aws" {
  region = "ca-central-1"
}

module "gcp_vpn" {
  source = "../../modules/gcp/vpn"

  psk       = "${module.aws_vpn.psk}"
  asn       = "${module.aws_vpn.tun_asn}"
  network   = "${data.terraform_remote_state.google.network_self_link}"
  region    = "${data.terraform_remote_state.google.region}"
  aws_tun_addr = "${module.aws_vpn.tun_addr}"
  aws_bgp_asn = "${module.aws_vpn.bgp_asn}"
  aws_cgw_inside_address = "${module.aws_vpn.cgw_inside_address}"
  aws_vgw_inside_address = "${module.aws_vpn.vgw_inside_address}"
  aws_public_subnet_cidr = "${data.terraform_remote_state.aws.public_subnet_cidr}"
  aws_private_subnet_cidr = "${data.terraform_remote_state.aws.private_subnet_cidr}"
}

module "aws_vpn" {
  source = "../../modules/aws/vpn"

  vpc_id        = "${data.terraform_remote_state.aws.vpc_id}"
  public_route_table_id = "${data.terraform_remote_state.aws.public_route_table_id}"
  private_route_table_id = "${data.terraform_remote_state.aws.private_route_table_id}"
  default_security_group_id = "${data.terraform_remote_state.aws.default_security_group_id}"
  igw_id        = "${data.terraform_remote_state.aws.igw_id}"
  gcp_vpn_ip    = "${module.gcp_vpn.vpn_ip}"
  gcp_public_subnet_cidr = "${data.terraform_remote_state.google.public_subnet_cidr}"
  gcp_private_subnet_cidr = "${data.terraform_remote_state.google.private_subnet_cidr}"
}
