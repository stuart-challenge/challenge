#--------------------------------------------------------------
# This module creates CloudFlare DNS resources
#--------------------------------------------------------------

variable "cloudflare_email"     { }
variable "cloudflare_token"     { }
variable "zone_name"            { }
variable "name"                 { }
variable "nameservers"          { type = "list" }

provider "cloudflare" {
  email = "${var.cloudflare_email}"
  token = "${var.cloudflare_token}"
}

resource "cloudflare_record" "zone_ns" {
  // Count can't be computed here
  count  = "4"
  domain = "${var.zone_name}"
  name   = "${var.name}"
  value  = "${replace(element(var.nameservers, count.index), "/[.]$/", "")}"
  type   = "NS"
  ttl    = 300
}
