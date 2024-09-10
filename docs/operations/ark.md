# Ark

Ark is deployed on a single host that runs on Leafcloud.
Data is stored in Leafcloud's object store.
An [Ansible playbook](https://github.com/stackhpc/ansible-pulpcore-config) automates deployment of Pulp and its dependencies using the [Pulp OCI images](https://pulpproject.org/pulp-oci-images/) and [Compose configuration](https://pulpproject.org/pulp-oci-images/docs/admin/tutorials/quickstart/#podman-or-docker-compose) provided by the Pulp project.

