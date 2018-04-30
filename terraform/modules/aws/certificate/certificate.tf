#--------------------------------------------------------------
# This module creates all certificate resources
#--------------------------------------------------------------

variable "zone_id"   { }
variable "zone_name" { }

resource "aws_acm_certificate" "router" {
  domain_name               = "${var.zone_name}"
  subject_alternative_names = ["*.${var.zone_name}"]
  validation_method         = "DNS"
}

resource "aws_route53_record" "cert_validation" {
  name      = "${aws_acm_certificate.router.domain_validation_options.0.resource_record_name}"
  type      = "${aws_acm_certificate.router.domain_validation_options.0.resource_record_type}"
  zone_id   = "${var.zone_id}"
  records   = ["${aws_acm_certificate.router.domain_validation_options.0.resource_record_value}"]
  ttl       = 60
}

resource "aws_route53_record" "cert_validation_2" {
  name      = "${aws_acm_certificate.router.domain_validation_options.1.resource_record_name}"
  type      = "${aws_acm_certificate.router.domain_validation_options.1.resource_record_type}"
  zone_id   = "${var.zone_id}"
  records   = ["${aws_acm_certificate.router.domain_validation_options.1.resource_record_value}"]
  ttl       = 60
}

resource "aws_acm_certificate_validation" "router" {
  certificate_arn           = "${aws_acm_certificate.router.arn}"
  validation_record_fqdns   = [
    "${aws_route53_record.cert_validation.fqdn}",
    "${aws_route53_record.cert_validation_2.fqdn}"
    ]
}

output "certificate_arn" { value = "${aws_acm_certificate_validation.router.certificate_arn}" }
