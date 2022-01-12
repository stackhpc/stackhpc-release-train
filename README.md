# StackHPC Release Train

StackHPC release automation

Release train documentation is available at https://stackhpc.github.io/stackhpc-release-train/.

## Installation

```
python3 -m venv venv
source venv/bin/activate
pip install -U pip
pip install -r requirements.txt
ansible-galaxy collection install -r requirements.yml -p ansible/collections
```

## Prerequisites

These playbooks may interact with the public Pulp server, ark.stackhpc.com, as
well as a private one running on SMS lab, pulp-server.internal.sms-cloud.

You may wish to install a Pulp CLI for interactive use, although this is not
required to run the playbooks:

```
sudo dnf -y install python3-pip
pip3 install pulp-cli[pygments] --user
pulp config create --username admin --base-url http://<pulp server>:8080 --password <password>
pulp status
```

## Usage

Set the Ansible Vault password:

```
export ANSIBLE_VAULT_PASSWORD_FILE=/path/to/vault/password
```

Playbooks may then be run as follows:

```
ansible-playbook -i ansible/inventory ansible/<playbook>
```

## Workflows

### Package repositories

The following workflow shows how updates to package repositories flow between
the Pulp services.

* `dev-pulp-repo-sync.yml`: Synchronise `ark` with upstream package repositories.
* `dev-pulp-repo-publication-cleanup.yml`: Work around an issue with Pulp syncing where multiple publications may exist for a single repository version, breaking the Ansible Squeezer `rpm_publication` module.
* `dev-pulp-repo-publish.yml`: Create development distributions on `ark` for any new package repository snapshots.
* `test-pulp-repo-version-update.yml`: Query `ark` for the latest distribution versions and update the version variables (`ansible/inventory/group_vars/all/test-pulp-repo-versions`). These changes should be committed to this repository.
* `test-pulp-repo-sync.yml`: Synchronise `test` with `ark`'s package repositories using `ark` version variables.
* `test-pulp-repo-publish.yml`: Create distributions on `test` for any new package repository snapshots.
* `test-repo-test.yml`: Test installing and using package repositories on `test`.
* `dev-pulp-repo-promote.yml`: Promote the set of `ark` distributions defined in version variables to releases.
* `dev-pulp-content-guards.yml`: Create certguard content-guards using CA certificates stored in Hashicorp Vault (https://vault.stackhpc.com)

### Container images

The following workflow shows how updates to container image repositories flow
between the Pulp services. Container images are first built via `kolla-build`,
then pushed to `ark` under the `stackhpc-dev` namespace.

* `dev-pulp-container-publish.yml`: Configure access control for development container distributions on `ark`.
* `test-pulp-container-sync.yml`: Synchronise `test` with container images from `stackhpc-dev` namespace on `ark`.
* `test-pulp-container-publish.yml`: Create distributions on `test` Pulp server for any new container images.
* `dev-pulp-container-promote.yml`: Promote a set of container images from `stackhpc-dev` to `stackhpc` namespace. The tag to be promoted is defined via `dev_pulp_repository_container_promotion_tag` which should be specified as an extra variable (`-e`).

### Other playbooks

* `dev-pulp-distribution-list.yml`: List available distributions in `ark`.
* `test-pulp-distribution-list.yml`: List available distributions in `test`.
