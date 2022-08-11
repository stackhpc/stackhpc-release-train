# Usage - content management workflows

Content is primarily managed using the Ansible playbooks and configuration in the [stackhpc-release-train](https://github.com/stackhpc/stackhpc-release-train) repository.
The [readme](https://github.com/stackhpc/stackhpc-release-train/blob/main/README.md) provides information on how to install dependencies and run playbooks.
The playbooks are designed to be run manually or via a GitHub Actions CI job.
This page covers the different workflows available for content management.
It may be necessary to combine multiple of these to achieve a desired outcome.

## Syncing package repositories

The [Sync package repositories](https://github.com/stackhpc/stackhpc-release-train/actions/workflows/package-sync.yml) workflow runs nightly and on demand.
It syncs package repositories in Ark with their upstream sources, then creates publications and distributions for any new content:

* `dev-pulp-repo-sync.yml`: Synchronise `ark` with upstream package repositories.
* `dev-pulp-repo-publication-cleanup.yml`: Work around an issue with Pulp syncing where multiple publications may exist for a single repository version, breaking the Ansible Squeezer `rpm_publication` module.
* `dev-pulp-repo-publish.yml`: Create development distributions on `ark` for any new package repository snapshots.

Next, it syncs new content in Ark to the test Pulp service:

* `test-pulp-repo-version-query.yml`: Query `ark` for the latest distribution versions and set the version map variable `test_pulp_repository_rpm_repo_versions`.
* `test-pulp-repo-sync.yml`: Synchronise `test` with `ark`'s package repositories using the version map variable `test_pulp_repository_rpm_repo_versions`.
* `test-pulp-repo-publish.yml`: Create distributions on `test` for any new package repository snapshots.

It may be necessary to run this workflow on demand if the nightly workflow fails, or if an upstream package has been updated since the last run, or if the repository configuration has been updated.
Use GitHub Actions to run this workflow, or to run it manually:

```
ansible-playbook -i ansible/inventory \
ansible/dev-pulp-repo-sync.yml \
ansible/dev-pulp-repo-publication-cleanup.yml \
ansible/dev-pulp-repo-publish.yml

ansible-playbook -i ansible/inventory \
ansible/test-pulp-repo-version-query.yml \
ansible/test-pulp-repo-sync.yml \
ansible/test-pulp-repo-publish.yml
```

If a set of versions other than the latest need to be synced from Ark to test, then it is possible to specify `test_pulp_repository_rpm_repo_versions` via an extra variables file. In this case, it is not necessary to run `test-pulp-repo-version-query.yml`.
For example:

```
ansible-playbook -i ansible/inventory \
ansible/test-pulp-repo-sync.yml \
ansible/test-pulp-repo-publish.yml
-e @test_pulp_repository_rpm_repo_versions.yml
```

Here, `test_pulp_repository_rpm_repo_versions.yml` contains the repository version map variable `test_pulp_repository_rpm_repo_versions`.
It maps package repository short names (in [ansible/inventory/group_vars/all/package-repos](https://github.com/stackhpc/stackhpc-release-train/blob/main/ansible/inventory/group_vars/all/package-repos)) to the version of that repository to sync and publish.
For example:

```
test_pulp_repository_rpm_repo_versions:
  centos_stream_8_appstream: 20211122T102435
  centos_stream_8_baseos: 20220101T143229
  ...
```

Configuration for package repositories is in:

* [ansible/inventory/group_vars/all/package-repos](https://github.com/stackhpc/stackhpc-release-train/blob/main/ansible/inventory/group_vars/all/package-repos).
* [ansible/inventory/group_vars/all/dev-pulp-repos](https://github.com/stackhpc/stackhpc-release-train/blob/main/ansible/inventory/group_vars/all/dev-pulp-repos).
* [ansible/inventory/group_vars/all/test-pulp-repos](https://github.com/stackhpc/stackhpc-release-train/blob/main/ansible/inventory/group_vars/all/test-pulp-repos).

New package repositories should be added to `rpm_package_repos` in `ansible/inventory/group_vars/all/package-repos`.

## Promoting package repositories

!!! note

    This should only be performed when package repositories are ready for release.

The [Promote package repositories](https://github.com/stackhpc/stackhpc-release-train/actions/workflows/package-promote.yml) workflow runs on demand.
It should be run when package repositories need to be released.
It runs the following playbooks:

* `dev-pulp-repo-version-query-kayobe.yml`: Query the Pulp repository versions defined in a Kayobe configuration repository and sets the version map variable `dev_pulp_distribution_rpm_promote_versions` based upon those versions. A path to a Kayobe configuration repository must be specified via `kayobe_config_repo_path`.
* `dev-pulp-repo-promote.yml`: Promote the set of `ark` distributions defined in the version map variable `dev_pulp_distribution_rpm_promote_versions` to releases.

Use GitHub Actions to run this workflow, or to run it manually:

```
ansible-playbook -i ansible/inventory \
ansible/dev-pulp-repo-version-query-kayobe.yml \
ansible/dev-pulp-repo-promote.yml \
-e kayobe_config_repo_path=../stackhpc-kayobe-config/
```

In this example, the Pulp repository versions defined in the `etc/kayobe/pulp-repo-versions.yml` file in `../stackhpc-kayobe-config` repository (relative to the current working directory) will be promoted to releases.

Alternatively, the set of versions to promote may be specified as an extra variables file:

```
ansible-playbook -i ansible/inventory \
ansible/dev-pulp-repo-promote.yml \
-e @dev_pulp_distribution_rpm_promote_versions.yml
```

Here, `dev_pulp_distribution_rpm_promote_versions.yml` contains the repository version map variable `dev_pulp_distribution_rpm_promote_versions`.
It maps package repository short names (in [ansible/inventory/group_vars/all/package-repos](https://github.com/stackhpc/stackhpc-release-train/blob/main/ansible/inventory/group_vars/all/package-repos)) to the version of that repository to promote.
For example:

```
dev_pulp_distribution_rpm_promote_versions:
  centos_stream_8_appstream: 20211122T102435
  centos_stream_8_baseos: 20220101T143229
  ...
```

## Updating package repository versions in Kayobe configuration

!!! note

    This procedure is expected to change.

The [Update Kayobe package repository versions](https://github.com/stackhpc/stackhpc-release-train/actions/workflows/package-update-kayobe.yml) workflow runs on demand.
It should be run when package repository versions in Kayobe need to be updated.
It runs the following playbooks:

* `test-pulp-repo-version-query.yml`: Query `ark` for the latest distribution versions and set the version map variable `test_pulp_repository_rpm_repo_versions`.
* `test-kayobe-repo-version-generate.yml`: Query stackhpc-kayobe-config for the current repository versions, then update them to the previously queried versions in `ark`.

It then stores the new versions YAML file as an artifact, which may be downloaded and manually applied to stackhpc-kayobe-config.
In future the workflow will be extended to create a PR.

Use GitHub Actions to run this workflow, or to run it manually:

```
ansible/test-pulp-repo-version-query.yml \
ansible/test-kayobe-repo-version-generate.yml \
-e kayobe_config_repo_path=./stackhpc-kayobe-config/
```

Package repository versions are stored in StackHPC Kayobe configuration in [etc/kayobe/pulp-repo-versions.yml](https://github.com/stackhpc/stackhpc-kayobe-config/blob/stackhpc/wallaby/etc/kayobe/pulp-repo-versions.yml).
Note that the updated versions are not necessarily released.
The generated file may be amended as necessary (in case not all updates are required), then copied to the StackHPC Kayobe configuration.

## Building container images

!!! note

    This procedure is expected to change.

The [Build Kolla container images](https://github.com/stackhpc/stackhpc-kayobe-config/actions/workflows/stackhpc-container-image-build.yml) workflow in the [stackhpc-kayobe-config](https://github.com/stackhpc/stackhpc-kayobe-config) repository runs on demand.
It should be run when new Kolla container images are required.
All images may be built, or a specific set of images.
The images will be pushed to Ark, and the container image tag shown in the output of the `Display the container image tag` step.

Instructions for building Kolla container images manually are provided in the [StackHPC kayobe config README](https://github.com/stackhpc/stackhpc-kayobe-config/blob/bf1396b8564b79344e4b6cfb934eab865ff1ad09/README.rst#L226).

## Updating container image tags in Kayobe configuration

!!! note

    This procedure is expected to change.

The image tag used deploy containers may be updated for all images in [etc/kayobe/kolla.yml](https://github.com/stackhpc/stackhpc-kayobe-config/blob/stackhpc/wallaby/etc/kayobe/kolla.yml), or for specific images in [etc/kayobe/kolla/globals.yml](https://github.com/stackhpc/stackhpc-kayobe-config/blob/stackhpc/wallaby/etc/kayobe/kolla/globals.yml).
Currently this is a manual process.

## Syncing container images

The [Sync container repositories](https://github.com/stackhpc/stackhpc-release-train/actions/workflows/container-sync.yml) workflow runs on demand.
It should be run when new container images have been pushed to Ark.
It runs the following playbooks:

* `dev-pulp-container-publish.yml`: Configure access control for development container distributions on `ark`.
* `test-pulp-container-sync.yml`: Synchronise `test` with container images from `stackhpc-dev` namespace on `ark`.
* `test-pulp-container-publish.yml`: Create distributions on `test` Pulp server for any new container images.

Use GitHub Actions to run this workflow, or to run it manually:

```
ansible-playbook -i ansible/inventory \
ansible/dev-pulp-container-publish.yml \
ansible/test-pulp-container-sync.yml \
ansible/test-pulp-container-publish.yml
```

Configuration for container images is in:

* [ansible/inventory/group_vars/all/kolla](https://github.com/stackhpc/stackhpc-release-train/blob/main/ansible/inventory/group_vars/all/kolla).
* [ansible/inventory/group_vars/all/dev-pulp-containers](https://github.com/stackhpc/stackhpc-release-train/blob/main/ansible/inventory/group_vars/all/dev-pulp-containers).
* [ansible/inventory/group_vars/all/test-pulp-containers](https://github.com/stackhpc/stackhpc-release-train/blob/main/ansible/inventory/group_vars/all/test-pulp-containers).

New images should be added to `kolla_container_images` in `ansible/inventory/group_vars/all/kolla`.

## Promoting container images

!!! note

    This should only be performed when container images are ready for release.

The [Promote container repositories](https://github.com/stackhpc/stackhpc-release-train/actions/workflows/container-promote.yml) workflow runs on demand.
It should be run when container images need to be released.
It runs the following playbook:

* `dev-pulp-container-promote.yml`: Promote a set of container images from `stackhpc-dev` to `stackhpc` namespace. The tag to be promoted is defined via `dev_pulp_repository_container_promotion_tag` which should be specified as an extra variable (`-e`).

Use GitHub Actions to run this workflow, or to run it manually:

```
ansible-playbook -i ansible/inventory \
ansible/dev-pulp-container-promote.yml
```

## Other utilities

* `dev-pulp-distribution-list.yml`: List available distributions in `ark`.
* `test-pulp-distribution-list.yml`: List available distributions in `test`.
* `test-repo-test.yml`: Install package repositories on the local machine and install some packages.
