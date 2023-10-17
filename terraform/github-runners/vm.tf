variable "vm_count" {
  type = number
}

variable "ssh_username" {
  type = string
}

variable "vm_name" {
  type    = string
  default = "srt-runner"
}

variable "vm_image" {
  type    = string
}

variable "vm_flavor" {
  type = string
}

variable "vm_network" {
  type = string
}

variable "vm_subnet" {
  type = string
}

locals {
  image_is_uuid = length(regexall("^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$", var.vm_image)) > 0
}

data "openstack_images_image_v2" "image" {
  name        = var.vm_image
  most_recent = true
  count       = local.image_is_uuid ? 0 : 1
}

data "openstack_networking_subnet_v2" "network" {
  name = var.vm_subnet
}

resource "openstack_compute_instance_v2" "runners" {
  count        = var.vm_count
  name         = format("%s%s", var.vm_name, count.index)
  flavor_name  = var.vm_flavor
  config_drive = true
  user_data    = file("templates/userdata.cfg.tpl")
  network {
    name = var.vm_network
  }

  block_device {
    uuid                  = local.image_is_uuid ? var.vm_image: data.openstack_images_image_v2.image[0].id
    source_type           = "image"
    volume_size           = 20
    boot_index            = 0
    destination_type      = "volume"
    delete_on_termination = true
  }
}
