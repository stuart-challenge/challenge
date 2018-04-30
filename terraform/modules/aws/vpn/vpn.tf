#--------------------------------------------------------------
# This module creates all VPN resources
#--------------------------------------------------------------

variable "vpc_id"  { }
variable "igw_id"  { }
variable "public_route_table_id" { }
variable "private_route_table_id" { }
variable "default_security_group_id" { }
variable "gcp_vpn_ip" { }
variable "gcp_public_subnet_cidr" { }
variable "gcp_private_subnet_cidr" { }

resource "aws_vpn_gateway" "vpn" {
  vpc_id = "${var.vpc_id}"
}

resource "aws_customer_gateway" "vpn" {
  bgp_asn    = 65000
  ip_address = "${var.gcp_vpn_ip}"
  type       = "ipsec.1"
}

resource "aws_vpn_gateway_route_propagation" "public" {
  vpn_gateway_id = "${aws_vpn_gateway.vpn.id}"
  route_table_id = "${var.public_route_table_id}"
}

resource "aws_vpn_gateway_route_propagation" "private" {
  vpn_gateway_id = "${aws_vpn_gateway.vpn.id}"
  route_table_id = "${var.private_route_table_id}"
}

resource "aws_vpn_connection" "vpn" {
  vpn_gateway_id      = "${aws_vpn_gateway.vpn.id}"
  customer_gateway_id = "${aws_customer_gateway.vpn.id}"
  type                = "ipsec.1"
  static_routes_only  = false
}

resource "aws_security_group_rule" "vpn" {
  type        = "ingress"
  from_port   = 0
  to_port     = 0
  protocol    = "-1"
  cidr_blocks = [
    "${var.gcp_public_subnet_cidr}",
    "${var.gcp_private_subnet_cidr}"
  ]
  security_group_id = "${var.default_security_group_id}"
}

output "tun_addr" { value = "${aws_vpn_connection.vpn.tunnel1_address}" }
output "tun_asn" { value = "${aws_vpn_connection.vpn.tunnel1_bgp_asn}" }
output "psk" { value = "${aws_vpn_connection.vpn.tunnel1_preshared_key}" }
output "bgp_asn" { value = "${aws_customer_gateway.vpn.bgp_asn}" }
output "cgw_inside_address" { value = "${aws_vpn_connection.vpn.tunnel1_cgw_inside_address}" }
output "vgw_inside_address" { value = "${aws_vpn_connection.vpn.tunnel1_vgw_inside_address}" }
