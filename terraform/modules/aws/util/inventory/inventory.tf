#--------------------------------------------------------------
# This module creates an Ansible inventory from Terraform
#--------------------------------------------------------------

variable "cluster_id"             { }
variable "access_key"             { }
variable "secret_key"             { }
variable "master_public_hostname" { }
variable "router_hostname"        { }
variable "master_hostname"        { }
variable "node_hostname"          { }

data "template_file" "inventory" {
  template = "${file("${path.cwd}/../inventory.tmpl.cfg")}"
  vars {
    cluster_id              = "${var.cluster_id}"
    access_key              = "${var.access_key}"
    secret_key              = "${var.secret_key}"
    master_public_hostname  = "${var.master_public_hostname}"
    router_hostname         = "${var.router_hostname}"
    master_hostname         = "${var.master_hostname}"
    node_hostname           = "${var.node_hostname}"
  }
}

resource "local_file" "inventory" {
  content  = "${data.template_file.inventory.rendered}"
  filename = "${path.cwd}/../inventory.cfg"
}
