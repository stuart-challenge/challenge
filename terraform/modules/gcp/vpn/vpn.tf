#--------------------------------------------------------------
# This module creates all VPN resources
#--------------------------------------------------------------

variable "region"  { }
variable "network" { }
variable "psk"     { }
variable "asn"     { }
variable "aws_tun_addr" { }
variable "aws_bgp_asn" { }
variable "aws_cgw_inside_address" { }
variable "aws_vgw_inside_address" { }
variable "aws_public_subnet_cidr" { }
variable "aws_private_subnet_cidr" { }

resource "google_compute_address" "vpn" {
  name   = "vpn-ip"
  region = "${var.region}"
}

resource "google_compute_vpn_gateway" "vpn" {
  name    = "vpn-gw"
  network = "${var.network}"
  region  = "${var.region}"
}

resource "google_compute_forwarding_rule" "vpn-esp" {
  name        = "vpn-esp"
  ip_protocol = "ESP"
  ip_address  = "${google_compute_address.vpn.address}"
  target      = "${google_compute_vpn_gateway.vpn.self_link}"
}

resource "google_compute_forwarding_rule" "vpn-500" {
  name        = "vpn-500"
  ip_protocol = "UDP"
  port_range  = "500-500"
  ip_address  = "${google_compute_address.vpn.address}"
  target      = "${google_compute_vpn_gateway.vpn.self_link}"
}

resource "google_compute_forwarding_rule" "vpn-4500" {
  name        = "vpn-4500"
  ip_protocol = "UDP"
  port_range  = "4500-4500"
  ip_address  = "${google_compute_address.vpn.address}"
  target      = "${google_compute_vpn_gateway.vpn.self_link}"
}

resource "google_compute_vpn_tunnel" "vpn" {
  name          = "vpn-tunnel"
  peer_ip       = "${var.aws_tun_addr}"
  shared_secret = "${var.psk}"
  ike_version   = 1

  target_vpn_gateway = "${google_compute_vpn_gateway.vpn.self_link}"

  router = "${google_compute_router.vpn.name}"

  depends_on = [
    "google_compute_forwarding_rule.vpn-esp",
    "google_compute_forwarding_rule.vpn-500",
    "google_compute_forwarding_rule.vpn-4500",
  ]
}

resource "google_compute_router" "vpn" {
  name = "vpn-router"
  region = "${var.region}"
  network = "${var.network}"
  bgp {
    asn = "${var.aws_bgp_asn}"
  }
}

resource "google_compute_router_peer" "vpn" {
  name = "gcp-to-aws"
  router  = "${google_compute_router.vpn.name}"
  region  = "${google_compute_router.vpn.region}"
  peer_ip_address = "${var.aws_vgw_inside_address}"
  peer_asn = "${var.asn}"
  interface = "${google_compute_router_interface.vpn.name}"
}

resource "google_compute_router_interface" "vpn" {
  name    = "gcp-to-aws"
  router  = "${google_compute_router.vpn.name}"
  region  = "${google_compute_router.vpn.region}"
  ip_range = "${var.aws_cgw_inside_address}/30"
  vpn_tunnel = "${google_compute_vpn_tunnel.vpn.name}"
}

resource "google_compute_firewall" "vpn" {
  name    = "openshift-vpn"
  network = "${var.network}"

  allow {
    protocol = "tcp"
    ports = ["0-65535"]
  }

  allow {
    protocol = "udp"
    ports = ["0-65535"]
  }

  source_ranges = [
    "${var.aws_public_subnet_cidr}",
    "${var.aws_private_subnet_cidr}"
  ]
}

output "vpn_ip" { value = "${google_compute_address.vpn.address}" }
