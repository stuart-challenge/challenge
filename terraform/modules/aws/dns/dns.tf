#--------------------------------------------------------------
# This module creates DNS resources
#--------------------------------------------------------------

variable "zone_name" { }
variable "master_api_name" { }
variable "master_zone_id"  { }
variable "router_name" { }
variable "router_zone_id"  { }
variable "master_ip" { }
variable "node_ip"   { }

resource "aws_route53_zone" "global" {
  name = "${var.zone_name}"
}

resource "aws_route53_record" "master" {
  zone_id = "${aws_route53_zone.global.zone_id}"
  name    = "master.${var.zone_name}"
  type    = "A"
  ttl     = 300
  records = [
      "${var.master_ip}"
  ]
}

resource "aws_route53_record" "node" {
  zone_id = "${aws_route53_zone.global.zone_id}"
  name    = "node.${var.zone_name}"
  type    = "A"
  ttl     = 300
  records = [
      "${var.node_ip}"
  ]
}

resource "aws_route53_record" "master_api" {
  zone_id = "${aws_route53_zone.global.zone_id}"
  name    = "master-api.${var.zone_name}"
  type    = "A"
  alias {
    name                   = "${var.master_api_name}"
    zone_id                = "${var.master_zone_id}"
    evaluate_target_health = true
  }
}

resource "aws_route53_record" "router" {
  zone_id = "${aws_route53_zone.global.zone_id}"
  name    = "${var.zone_name}"
  type    = "A"
  alias {
    name                   = "${var.router_name}"
    zone_id                = "${var.router_zone_id}"
    evaluate_target_health = true
  }
}

resource "aws_route53_record" "router_wildcard" {
  zone_id = "${aws_route53_zone.global.zone_id}"
  name    = "*.${var.zone_name}"
  type    = "A"
  alias {
    name                   = "${var.router_name}"
    zone_id                = "${var.router_zone_id}"
    evaluate_target_health = true
  }
}

output "nameservers" { value="${aws_route53_zone.global.name_servers}" }
output "zone_id" { value="${aws_route53_zone.global.zone_id}" }
output "master_api_hostname" { value = "${aws_route53_record.master_api.fqdn}" }
output "router_hostname" { value = "${aws_route53_record.router.fqdn}" }
output "master_hostname" { value = "${aws_route53_record.master.fqdn}" }
output "node_hostname" { value = "${aws_route53_record.node.fqdn}" }
