#--------------------------------------------------------------
# This module creates an Ansible inventory from Terraform
#--------------------------------------------------------------

variable "project"                { }
variable "cluster_id"             { }
variable "master_public_hostname" { }
variable "router_hostname"        { }
variable "master_name"            { }
variable "node_name"              { }

data "template_file" "inventory" {
  template = "${file("${path.cwd}/../inventory.tmpl.cfg")}"
  vars {
    project                 = "${var.project}"
    cluster_id              = "${var.cluster_id}"
    master_public_hostname  = "${var.master_public_hostname}"
    router_hostname         = "${var.router_hostname}"
    master_hostname         = "${var.master_name}"
    node_hostname           = "${var.node_name}"
  }
}

resource "local_file" "inventory" {
  content  = "${data.template_file.inventory.rendered}"
  filename = "${path.cwd}/../inventory.cfg"
}
