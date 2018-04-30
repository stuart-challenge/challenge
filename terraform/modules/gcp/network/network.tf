#--------------------------------------------------------------
# This module creates all networking resources
#--------------------------------------------------------------

variable "region"             { }
variable "vpc_cidr"           { }
variable "allowed_cidrs"      { }
variable "admin_cidrs"        { }


resource "google_compute_network" "openshift" {
  name                    = "openshift"
  auto_create_subnetworks = "false"
}

resource "google_compute_subnetwork" "public" {
  name          = "public"
  network       = "${google_compute_network.openshift.self_link}"
  ip_cidr_range = "${cidrsubnet(var.vpc_cidr, 8, 0)}"
  region        = "${var.region}"
}

resource "google_compute_subnetwork" "private" {
  name          = "private"
  network       = "${google_compute_network.openshift.self_link}"
  ip_cidr_range = "${cidrsubnet(var.vpc_cidr, 8, 1)}"
  region        = "${var.region}"
}

resource "google_compute_firewall" "openshift_public" {
  name    = "openshift-public-firewall"
  network = "${google_compute_network.openshift.self_link}"

  allow {
    protocol = "icmp"
  }

  allow {
    protocol = "tcp"
    ports    = ["80", "443"]
  }

  source_ranges = ["${split(",", var.allowed_cidrs)}"]
}

resource "google_compute_firewall" "openshift_private" {
  name    = "openshift-private-firewall"
  network = "${google_compute_network.openshift.self_link}"

  allow {
    protocol = "tcp"
    ports    = ["8443"]
  }

  source_ranges = ["${split(",", var.allowed_cidrs)}"]
}

resource "google_compute_firewall" "openshift_private_ssh" {
  name    = "openshift-private-ssh-firewall"
  network = "${google_compute_network.openshift.self_link}"

  allow {
    protocol = "tcp"
    ports    = ["22"]
  }

  source_ranges = ["${split(",", var.admin_cidrs)}"]
}

resource "google_compute_firewall" "openshift_internal" {
  name    = "openshift-internal-firewall"
  network = "${google_compute_network.openshift.self_link}"

  allow {
    protocol = "icmp"
  }

  allow {
    protocol = "tcp"
    ports    = ["0-65535"]
  }

  allow {
    protocol = "udp"
    ports    = ["0-65535"]
  }

  source_ranges = ["${var.vpc_cidr}"]
}

output "network_self_link" { value = "${google_compute_network.openshift.self_link}" }
output "public_subnet_cidr" { value = "${google_compute_subnetwork.public.ip_cidr_range}" }
output "private_subnet_cidr" { value = "${google_compute_subnetwork.private.ip_cidr_range}" }
output "public_subnetwork_self_link" { value = "${google_compute_subnetwork.public.self_link}" }
output "private_subnetwork_self_link" { value = "${google_compute_subnetwork.private.self_link}" }
