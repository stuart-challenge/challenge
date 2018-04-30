#--------------------------------------------------------------
# This module creates all networking resources
#--------------------------------------------------------------

variable "name"       { }
variable "cluster_id" { }

variable "vpc_cidr" { }
variable "az"       { }

locals {
  common_tags = "${map(
    "Project", "${var.name}",
    "kubernetes.io/cluster/${var.name}", "${var.cluster_id}"
  )}"
}

resource "aws_vpc" "vpc" {
  cidr_block            = "${var.vpc_cidr}"
  enable_dns_support    = true
  enable_dns_hostnames  = true

  tags = "${merge(
    local.common_tags,
    map(
      "Name", "${var.name}"
    )
  )}"

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_internet_gateway" "public" {
  vpc_id = "${aws_vpc.vpc.id}"

  tags = "${merge(
    local.common_tags,
    map(
      "Name", "${var.name}-public-gw"
    )
  )}"
}

resource "aws_subnet" "public" {
  vpc_id                    = "${aws_vpc.vpc.id}"
  cidr_block                = "${cidrsubnet(aws_vpc.vpc.cidr_block, 8, 0)}"
  availability_zone         = "${var.az}"
  map_public_ip_on_launch   = true

  tags = "${merge(
    local.common_tags,
    map(
      "Name", "${var.name}-public"
    )
  )}"

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_route_table" "public" {
  vpc_id = "${aws_vpc.vpc.id}"

  route {
    cidr_block  = "0.0.0.0/0"
    gateway_id  = "${aws_internet_gateway.public.id}"
  }

  tags = "${merge(
    local.common_tags,
    map(
      "Name", "${var.name}-public-rt"
    )
  )}"
}

resource "aws_route_table_association" "public" {
  subnet_id      = "${aws_subnet.public.id}"
  route_table_id = "${aws_route_table.public.id}"
}


resource "aws_subnet" "private" {
  vpc_id                          = "${aws_vpc.vpc.id}"
  cidr_block                      = "${cidrsubnet(aws_vpc.vpc.cidr_block, 8, 1)}"
  availability_zone               = "${var.az}"

  tags = "${merge(
    local.common_tags,
    map(
      "Name", "${var.name}-private"
    )
  )}"

  lifecycle {
    create_before_destroy = true
    }
}

resource "aws_eip" "private-gw" {
    vpc = true
}

resource "aws_nat_gateway" "private" {
  allocation_id = "${aws_eip.private-gw.id}"
  subnet_id = "${aws_subnet.public.id}"

  tags = "${merge(
    local.common_tags,
    map(
      "Name", "${var.name}-private-gw"
    )
  )}"
}

resource "aws_route_table" "private" {
  vpc_id = "${aws_vpc.vpc.id}"

  route {
    cidr_block  = "0.0.0.0/0"
    nat_gateway_id  = "${aws_nat_gateway.private.id}"
  }

  tags = "${merge(
    local.common_tags,
    map(
      "Name", "${var.name}-private-rt"
    )
  )}"
}

resource "aws_route_table_association" "private" {
  subnet_id      = "${aws_subnet.private.id}"
  route_table_id = "${aws_route_table.private.id}"
}

output "vpc_id"   { value = "${aws_vpc.vpc.id}" }
output "vpc_cidr" { value = "${aws_vpc.vpc.cidr_block}" }
output "vpc_default_security_group_id" { value = "${aws_vpc.vpc.default_security_group_id}" }
output "igw_id"   { value = "${aws_internet_gateway.public.id}" }
output "public_route_table_id" { value = "${aws_route_table.public.id}" }
output "private_route_table_id" { value = "${aws_route_table.private.id}" }
output "public_subnet_id" { value = "${aws_subnet.public.id}" }
output "public_subnet_cidr" { value = "${aws_subnet.public.cidr_block}" }
output "private_subnet_id" { value = "${aws_subnet.private.id}" }
output "private_subnet_cidr" { value = "${aws_subnet.private.cidr_block}" }
