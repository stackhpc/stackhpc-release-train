output "access_ip_v4" {
  value = openstack_compute_instance_v2.runners.*.access_ip_v4
}

output "access_cidr" {
  value = data.openstack_networking_subnet_v2.network.cidr
}

output "access_gw" {
  value = data.openstack_networking_subnet_v2.network.gateway_ip
}

resource "ansible_host" "runners" {
  for_each = { for host in openstack_compute_instance_v2.runners : host.name => host.access_ip_v4 }
  name = each.value
  groups = ["runners"]
}

resource "ansible_group" "runners" {
  name     = "runners"
  variables = {
    ansible_user = var.ssh_username
  }
}
