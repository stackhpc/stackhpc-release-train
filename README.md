# StackHPC Release Train

StackHPC release automation

## Background

This codebase includes playbooks for managing content in Pulp servers for the
StackHPC release train.

There are two Pulp servers involved:

* https://ark.stackhpc.com is a public-facing service hosted on Leafcloud. This
  provides content to StackHPC clients. It will be referred to as `ark` here.
* http://pulp-server.internal.sms-cloud is an internal service running on SMS
  lab.  This is used to provide a local content mirror for testing. It will be
  referred to as `test` here.

In general, new content is first synced or pushed to `ark`, then synced to
`test`. By default, new content is not accessible to clients on `ark`. Content
must be promoted in order to become accessible to clients.

Access to package repositories is controlled via x509 cert guards, while access
to container images is controlled via token authentication which uses Django
users in the backend.

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

### Container images

The following workflow shows how updates to container image repositories flow
between the Pulp services. Container images are first built via `kolla-build`,
then pushed to `ark` under the `stackhpc-dev` namespace.

* `dev-pulp-container-publish.yml`: Configure access control for development container distributions on `ark`.
* `test-pulp-container-sync.yml`: Synchronise `test` with container images from `stackhpc-dev` namespace on `ark`.
* `test-pulp-container-publish.yml`: Create distributions on `test` Pulp server for any new container images.
* `dev-pulp-container-promote.yml`: Promote a set of container images from `stackhpc-dev` to `stackhpc` namespace. The tag to be promoted is defined via `dev_pulp_repository_container_promotion_tag` in `ansible/inventory/group_vars/all/dev-pulp-containers`.

### Other playbooks

* `dev-pulp-distribution-list.yml`: List available distributions in `ark`.
* `test-pulp-distribution-list.yml`: List available distributions in `test`.
