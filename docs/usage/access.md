# Usage - access control

Access control is primarily managed using the Ansible playbooks and configuration in the [stackhpc-release-train](https://github.com/stackhpc/stackhpc-release-train) and [stackhpc-release-train-clients](https://github.com/stackhpc/stackhpc-release-train-clients) repositories.
The readme file in each repository provides information on how to install dependencies and run playbooks.
The playbooks are designed to be run manually or via a Github Actions CI job.
This page covers the different workflows available for access control.

## Create content guards

This workflow must currently be run manually.
It involves the following playbook in the [stackhpc-release-train](https://github.com/stackhpc/stackhpc-release-train) repository:

* `dev-pulp-content-guards.yml`: Create certguard content-guards using CA certificates stored in Hashicorp Vault (https://vault.stackhpc.com)

This should only need to be run when the CA chain for the content guards changes, which should be very rare.

To run it manually:

```
ansible-playbook -i ansible/inventory \
ansible/dev-pulp-content-guards.yml
```

Configuration for content guards is in [ansible/inventory/group_vars/all/dev-pulp-repos](https://github.com/stackhpc/stackhpc-release-train/blob/main/ansible/inventory/group_vars/all/dev-pulp-repos).

## Generating client credentials

TODO
