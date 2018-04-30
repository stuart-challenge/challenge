#--------------------------------------------------------------
# This module creates all compute resources
#--------------------------------------------------------------

variable "name"               { }
variable "cluster_id"         { }
variable "region"             { }
variable "vpc_id"             { }
variable "vpc_cidr"           { }
variable "vpc_default_security_group_id" { }
variable "ssh_key_name"       { }
variable "az"                 { }
variable "public_subnet_id"   { }
variable "private_subnet_id"  { }
variable "instance_profile_id" { }
variable "allowed_cidrs"      { }
variable "admin_cidrs"        { }
variable "certificate_arn"    { }

variable "openshift_ami"            { }
variable "openshift_instance_type"  { }
variable "bastion_instance_type"    { }
variable "bastion_ami"              { }

locals {
  common_tags = "${map(
    "Project", "${var.name}",
    "kubernetes.io/cluster/${var.name}", "${var.cluster_id}"
  )}"
}

resource "aws_security_group" "bastion" {
  name        = "${var.name}-bastion-sg"
  vpc_id      = "${var.vpc_id}"

  lifecycle {
    create_before_destroy = true
  }

  ingress {
    protocol    = "tcp"
    from_port   = 22
    to_port     = 22
    cidr_blocks = ["${split(",", var.admin_cidrs)}"]
  }

  egress {
    protocol          = "-1"
    from_port         = 0
    to_port           = 0
    cidr_blocks       = ["0.0.0.0/0"]
  }

  tags = "${merge(
    local.common_tags,
    map(
      "Name", "${var.name}-bastion-sg"
    )
  )}"
}

resource "aws_security_group" "public_ingress" {
  name        = "${var.name}-public-ingress-sg"
  vpc_id      = "${var.vpc_id}"

  ingress {
    protocol    = "tcp"
    from_port   = 80
    to_port     = 80
    cidr_blocks = ["${split(",", var.allowed_cidrs)}"]
  }

  ingress {
    protocol    = "tcp"
    from_port   = 443
    to_port     = 443
    cidr_blocks = ["${split(",", var.allowed_cidrs)}"]
  }

  tags = "${merge(
    local.common_tags,
    map(
      "Name", "${var.name}-public-ingress-sg"
    )
  )}"
}

resource "aws_security_group" "master_api" {
  name        = "${var.name}-public-master-api-sg"
  vpc_id      = "${var.vpc_id}"

  ingress {
    protocol    = "tcp"
    from_port   = 8443
    to_port     = 8443
    cidr_blocks = ["${split(",", var.admin_cidrs)}"]
  }

  tags = "${merge(
    local.common_tags,
    map(
      "Name", "${var.name}-public-master-api-sg"
    )
  )}"
}

resource "aws_instance" "bastion" {
  ami                  = "${var.bastion_ami}"
  instance_type        = "${var.bastion_instance_type}"
  iam_instance_profile = "${var.instance_profile_id}"
  subnet_id            = "${var.public_subnet_id}"

  vpc_security_group_ids = [
    "${var.vpc_default_security_group_id}",
    "${aws_security_group.bastion.id}",
  ]

  key_name = "${var.ssh_key_name}"

  tags = "${merge(
    local.common_tags,
    map(
      "Name", "${var.name}-bastion"
    )
  )}"
}

resource "aws_instance" "master" {
  ami                  = "${var.openshift_ami}"
  instance_type        = "${var.openshift_instance_type}"
  iam_instance_profile = "${var.instance_profile_id}"
  subnet_id            = "${var.private_subnet_id}"

  vpc_security_group_ids = [
    "${var.vpc_default_security_group_id}",
    "${aws_security_group.public_ingress.id}",
  ]

  key_name = "${var.ssh_key_name}"

  root_block_device {
    volume_size = 50
    volume_type = "gp2"
  }

  ebs_block_device {
    device_name = "/dev/sdf"
    volume_size = 80
    volume_type = "gp2"
  }

  lifecycle {
    ignore_changes = [ "ebs_block_device" ]
  }

  tags = "${merge(
    local.common_tags,
    map(
      "Name", "${var.name}-master"
    )
  )}"
}

resource "aws_instance" "node" {
  ami                  = "${var.openshift_ami}"
  instance_type        = "${var.openshift_instance_type}"
  iam_instance_profile = "${var.instance_profile_id}"
  subnet_id            = "${var.private_subnet_id}"

  vpc_security_group_ids = [
    "${var.vpc_default_security_group_id}",
    "${aws_security_group.public_ingress.id}",
    "${aws_security_group.master_api.id}",
  ]

  key_name = "${var.ssh_key_name}"

  root_block_device {
    volume_size = 50
    volume_type = "gp2"
  }

  ebs_block_device {
    device_name = "/dev/sdf"
    volume_size = 80
    volume_type = "gp2"
  }

  lifecycle {
    ignore_changes = [ "ebs_block_device" ]
  }

  tags = "${merge(
    local.common_tags,
    map(
      "Name", "${var.name}-node"
    )
  )}"
}

resource "aws_elb" "openshift_master_api" {
  name                = "openshift-master-api"
  subnets             = ["${var.public_subnet_id}"]
  instances           = ["${aws_instance.master.id}"]
  security_groups     = ["${var.vpc_default_security_group_id}", "${aws_security_group.master_api.id}"]

  listener {
    instance_port      = 8443
    instance_protocol  = "ssl"
    lb_port            = 8443
    lb_protocol        = "ssl"
    ssl_certificate_id = "${var.certificate_arn}"
  }

  health_check {
    healthy_threshold   = 2
    unhealthy_threshold = 2
    timeout             = 15
    target              = "TCP:8443"
    interval            = 30
  }

  tags = "${merge(
    local.common_tags,
    map(
      "Name", "${var.name}-master-api"
    )
  )}"
}

resource "aws_elb" "openshift_public" {
  name                = "openshift-public"
  subnets             = ["${var.public_subnet_id}"]
  instances           = ["${aws_instance.master.id}"]
  security_groups     = ["${var.vpc_default_security_group_id}", "${aws_security_group.public_ingress.id}"]

  listener {
    instance_port      = 80
    instance_protocol  = "tcp"
    lb_port            = 80
    lb_protocol        = "tcp"
  }

  listener {
    instance_port      = 443
    instance_protocol  = "tcp"
    lb_port            = 443
    lb_protocol        = "tcp"
  }

  health_check {
    healthy_threshold   = 2
    unhealthy_threshold = 2
    timeout             = 15
    target              = "TCP:80"
    interval            = 30
  }

  tags = "${merge(
    local.common_tags,
    map(
      "Name", "${var.name}-public"
    )
  )}"
}


output "master_hostname" { value = "${aws_instance.master.private_dns}" }
output "master_public_hostname" { value = "${aws_elb.openshift_master_api.dns_name}" }
output "master_public_zone_id" { value = "${aws_elb.openshift_master_api.zone_id}" }
output "node_hostname" { value = "${aws_instance.node.private_dns}" }
output "router_public_hostname" { value = "${aws_elb.openshift_public.dns_name}" }
output "router_public_zone_id" { value = "${aws_elb.openshift_public.zone_id}" }
output "master_ip" { value = "${aws_instance.master.private_ip}" }
output "node_ip" { value = "${aws_instance.node.private_ip}" }
output "bastion_public_ip" { value = "${aws_instance.bastion.public_ip}" }
