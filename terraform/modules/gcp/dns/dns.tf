#--------------------------------------------------------------
# This module creates DNS resources
#--------------------------------------------------------------

variable "zone_name" { }
variable "master_ip" { }
variable "master_public_ip" { }
variable "router_ip" { }
variable "node_ip"   { }


resource "google_dns_managed_zone" "openshift" {
  name        = "openshift-zone"
  dns_name    = "${var.zone_name}."
}

resource "google_dns_record_set" "master" {
  name = "master.${google_dns_managed_zone.openshift.dns_name}"
  managed_zone = "${google_dns_managed_zone.openshift.name}"
  type = "A"
  ttl  = 300

  rrdatas = ["${var.master_ip}"]
}

resource "google_dns_record_set" "node" {
  name = "node.${google_dns_managed_zone.openshift.dns_name}"
  managed_zone = "${google_dns_managed_zone.openshift.name}"
  type = "A"
  ttl  = 300

  rrdatas = ["${var.node_ip}"]
}

resource "google_dns_record_set" "master_api" {
  name = "master-api.${google_dns_managed_zone.openshift.dns_name}"
  managed_zone = "${google_dns_managed_zone.openshift.name}"
  type = "A"
  ttl  = 300

  rrdatas = ["${var.master_public_ip}"]
}

resource "google_dns_record_set" "router" {
  name = "${google_dns_managed_zone.openshift.dns_name}"
  managed_zone = "${google_dns_managed_zone.openshift.name}"
  type = "A"
  ttl  = 300

  rrdatas = ["${var.router_ip}"]
}

resource "google_dns_record_set" "router_wildcard" {
  name = "*.${google_dns_managed_zone.openshift.dns_name}"
  managed_zone = "${google_dns_managed_zone.openshift.name}"
  type = "A"
  ttl  = 300

  rrdatas = ["${var.router_ip}"]
}

output "nameservers" { value = "${google_dns_managed_zone.openshift.name_servers}" }
output "master_api_hostname" { value = "master-api.${var.zone_name}" }
output "router_hostname" { value = "${var.zone_name}" }
output "master_hostname" { value = "master.${var.zone_name}" }
output "node_hostname" { value = "node.${var.zone_name}" }
