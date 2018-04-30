#--------------------------------------------------------------
# This module creates all compute resources
#--------------------------------------------------------------

variable "zone"                { }
variable "public_network"      { }
variable "private_network"     { }
variable "ssh_key_name"        { }
variable "ssh_public_key"      { }
variable "machine_image"       { }
variable "admin_cidrs"         { }
variable "public_subnet_cidr"  { }
variable "private_subnet_cidr" { }

variable "openshift_machine_type"   { }
variable "bastion_machine_type"     { }

resource "google_compute_disk" "bastion" {
  name  = "bastion-disk"
  type  = "pd-ssd"
  zone  = "${var.zone}"
  image = "${var.machine_image}"
}

resource "google_compute_disk" "master" {
  name  = "master-disk"
  type  = "pd-ssd"
  zone  = "${var.zone}"
  image = "${var.machine_image}"
  size  = 50
}

resource "google_compute_disk" "node" {
  name  = "node-disk"
  type  = "pd-ssd"
  zone  = "${var.zone}"
  image = "${var.machine_image}"
  size  = 50
}

resource "google_compute_disk" "master_docker" {
  name  = "master-docker-disk"
  type  = "pd-ssd"
  zone  = "${var.zone}"
  size  = 80
}

resource "google_compute_disk" "node_docker" {
  name  = "node-docker-disk"
  type  = "pd-ssd"
  zone  = "${var.zone}"
  size  = 80
}

resource "google_compute_address" "bastion" {
  name = "bastion-address"
}

resource "google_compute_address" "master" {
  name = "master-address"
}

resource "google_compute_address" "router" {
  name = "router-address"
}

resource "google_compute_global_address" "master-api" {
  name = "master-api-address"
}

resource "google_compute_instance" "bastion" {
  name         = "bastion"
  machine_type = "${var.bastion_machine_type}"
  zone         = "${var.zone}"

  boot_disk {
    source = "${google_compute_disk.bastion.self_link}"
  }

  network_interface {
    subnetwork = "${var.public_network}"

    access_config {
      nat_ip = "${google_compute_address.bastion.address}"
    }
  }

  metadata {
    sshKeys = "${var.ssh_key_name}:${var.ssh_public_key}"
  }

  service_account {
    scopes = ["userinfo-email", "compute-ro", "storage-ro"]
  }
}

resource "google_compute_instance" "master" {
  name         = "master"
  machine_type = "${var.openshift_machine_type}"
  zone         = "${var.zone}"

  boot_disk {
    source = "${google_compute_disk.master.self_link}"
  }

  attached_disk {
    source = "${google_compute_disk.master_docker.self_link}"
    device_name = "docker"
  }

  network_interface {
    subnetwork = "${var.private_network}"

    access_config {
    }
  }

  metadata {
    sshKeys = "${var.ssh_key_name}:${var.ssh_public_key}"
  }

  service_account {
    scopes = ["userinfo-email", "compute-ro", "storage-ro"]
  }
}

resource "google_compute_instance" "node" {
  name         = "node"
  machine_type = "${var.openshift_machine_type}"
  zone         = "${var.zone}"

  boot_disk {
    source = "${google_compute_disk.node.self_link}"
  }

  attached_disk {
    source = "${google_compute_disk.node_docker.self_link}"
    device_name = "docker"
  }

  network_interface {
    subnetwork = "${var.private_network}"

    access_config {
    }
  }

  metadata {
    sshKeys = "${var.ssh_key_name}:${var.ssh_public_key}"
  }

  service_account {
    scopes = ["userinfo-email", "compute-ro", "storage-ro"]
  }
}

resource "google_compute_instance_group" "master-api" {
  name        = "master-api"
  zone        = "${var.zone}"

  instances = [
    "${google_compute_instance.master.self_link}"
  ]

  named_port {
    name = "https"
    port = "8443"
  }
}

resource "google_compute_health_check" "master-api" {
  name                = "master-api-health-check"
  check_interval_sec  = 5
  timeout_sec         = 5
  healthy_threshold   = 2
  unhealthy_threshold = 10

  tcp_health_check {
    port = "8443"
  }
}

resource "google_compute_backend_service" "master-api" {
  name        = "master-api"
  port_name   = "https"
  protocol    = "HTTPS"
  timeout_sec = 10
  enable_cdn  = false

  backend {
    group = "${google_compute_instance_group.master-api.self_link}"
  }

  security_policy = "${google_compute_security_policy.master-api.self_link}"
  health_checks = ["${google_compute_health_check.master-api.self_link}"]
}

resource "google_compute_global_forwarding_rule" "master-api" {
  name       = "master-api"
  target     = "${google_compute_target_https_proxy.master-api.self_link}"
  ip_address = "${google_compute_global_address.master-api.address}"
  port_range = "443"
}

resource "google_compute_target_https_proxy" "master-api" {
  name        = "master-api"
  url_map     = "${google_compute_url_map.master-api.self_link}"
  ssl_certificates = ["${google_compute_ssl_certificate.master-api.self_link}"]
}

resource "google_compute_ssl_certificate" "master-api" {
  name        = "master-api"
  private_key = "${file("../../../../certificates/gce/private.key")}"
  certificate = "${file("../../../../certificates/gce/cert.crt")}"

  lifecycle {
    create_before_destroy = true
  }
}

resource "google_compute_url_map" "master-api" {
  name            = "master-api"
  default_service = "${google_compute_backend_service.master-api.self_link}"
}

resource "google_compute_target_pool" "master" {
  name = "master-pool"

  instances = [
    "${google_compute_instance.master.self_link}",
  ]
}

resource "google_compute_forwarding_rule" "master-80" {
  name       = "master-80-rule"
  target     = "${google_compute_target_pool.master.self_link}"
  port_range = "80"
  ip_address = "${google_compute_address.router.address}"
}

resource "google_compute_forwarding_rule" "master-443" {
  name       = "master-443-rule"
  target     = "${google_compute_target_pool.master.self_link}"
  port_range = "443"
  ip_address = "${google_compute_address.router.address}"
}

resource "google_compute_security_policy" "master-api" {
  name = "master-api"

  rule {
    action   = "allow"
    priority = "1000"
    match {
      versioned_expr = "SRC_IPS_V1"
      config {
        src_ip_ranges = [
          "${split(",", var.admin_cidrs)}",
          "${var.public_subnet_cidr}",
          "${var.private_subnet_cidr}"
          ]
      }
    }
    description = "default rule"
  }

  rule {
    action   = "deny(403)"
    priority = "2147483647"
    match {
      versioned_expr = "SRC_IPS_V1"
      config {
        src_ip_ranges = ["*"]
      }
    }
  }
}

output "bastion_public_ip" { value = "${google_compute_instance.bastion.network_interface.0.access_config.0.assigned_nat_ip}" }
output "master_public_ip" { value = "${google_compute_global_address.master-api.address}" }
output "master_name" { value = "${google_compute_instance.master.name}" }
output "master_ip" { value = "${google_compute_instance.master.network_interface.0.address}" }
output "node_name" { value = "${google_compute_instance.node.name}" }
output "node_ip" { value = "${google_compute_instance.node.network_interface.0.address}" }
output "router_ip" { value = "${google_compute_address.router.address}"  }
