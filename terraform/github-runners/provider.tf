#provider "openstack" {
# use environment variables
#}

terraform {
  required_version = ">= 0.14"
  backend "local" {
  }
  required_providers {
    ansible = {
      source = "ansible/ansible"
      version = "1.1.0"
    }
    openstack = {
      source = "terraform-provider-openstack/openstack"
    }
  }
}
