# Usage - content management workflows

Content is primarily managed using the Ansible playbooks and configuration in the [stackhpc-release-train](https://github.com/stackhpc/stackhpc-release-train) repository.
The [readme](https://github.com/stackhpc/stackhpc-release-train/blob/main/README.md) provides information on how to install dependencies and run playbooks.
The playbooks are designed to be run manually or via a GitHub Actions CI job.
This page covers the different workflows available for content management.
It may be necessary to combine multiple of these to achieve a desired outcome.

## Add new package repositories to Release Train

Configuration for package repositories is in:

* [ansible/inventory/group_vars/all/package-repos](https://github.com/stackhpc/stackhpc-release-train/blob/main/ansible/inventory/group_vars/all/package-repos)

New package repositories should be added to `rpm_package_repos` or `deb_package_repos` in `ansible/inventory/group_vars/all/package-repos`.
The format of these variables is defined in the same file.

The following files contain information derived from the above variables and should not need to be modified:

* [ansible/inventory/group_vars/all/dev-pulp-repos](https://github.com/stackhpc/stackhpc-release-train/blob/main/ansible/inventory/group_vars/all/dev-pulp-repos)
* [ansible/inventory/group_vars/all/test-pulp-repos](https://github.com/stackhpc/stackhpc-release-train/blob/main/ansible/inventory/group_vars/all/test-pulp-repos)

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

## Promoting package repositories

!!! note

    This should only be performed when package repositories are ready for release.

The [Promote package repositories](https://github.com/stackhpc/stackhpc-release-train/actions/workflows/package-promote.yml) workflow is triggered automatically when a change is merged to stackhpc-kayobe-config.
It may also be run on demand.

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

## Adding package repositories in Kayobe configuration

Adding a package repository to the StackHPC Release Train configuration is not sufficient to allow StackHPC OpenStack deployments to use it.
The repository must also be defined in StackHPC Kayobe Configuration.
We need to define how to sync the package repository from Ark into the local Pulp, as well as how control plane hosts access the repository in the local Pulp service.

In the following steps, the `short_name` of a repository is the `short_name` field of the repository in [ansible/inventory/group_vars/all/package-repos](https://github.com/stackhpc/stackhpc-release-train/blob/main/ansible/inventory/group_vars/all/package-repos).

* Add details of the repository to `stackhpc_pulp_rpm_repos` or `stackhpc_pulp_deb_repos` in `etc/kayobe/pulp.yml` to enable syncing of the repository to the local Pulp service. Use the `required` field to avoid growing sync durations by controlling when the repository needs to be synced.
* Add a version variable to `etc/kayobe/pulp.yml`. It should have a format of `stackhpc_pulp_repo_<short_name>_version`. The version value may be specified or omitted. If omitted, it can be populated automatically using the [Update Kayobe package repository versions](https://github.com/stackhpc/stackhpc-release-train/actions/workflows/package-update-kayobe.yml) workflow.
* Add local Pulp URL and version variables for the repository to `etc/kayobe/stackhpc.yml`. They should have a format of `stackhpc_repo_<short_name>_url` and `stackhpc_repo_<short_name>_version`.
* Override the repository version variable in `stackhpc-ci.yml` in the `ci-aio`, `ci-builder` and `ci-multinode` Kayobe environments to use the datestamped version.
* If the repository needs to be accessible to the host OS of control plane hosts, add it to `etc/kayobe/dnf.yml` or `etc/kayobe/apt.yml`.
* If the repository needs to be accessible to Kolla container images, add it to the `Kolla image build configuration` section in `etc/kayobe/kolla.yml`.

## Building container images

!!! note

    This procedure is expected to change.

The [Build Kolla container images](https://github.com/stackhpc/stackhpc-kayobe-config/actions/workflows/stackhpc-container-image-build.yml) workflow in the [stackhpc-kayobe-config](https://github.com/stackhpc/stackhpc-kayobe-config) repository runs on demand.
It should be run when new Kolla container images are required.
All images may be built, or a specific set of images.
All successfully built images will be pushed to Ark, in the `stackhpc-dev` namespace.
An `Overcloud container images` artifact will be visible on the summary page of a completed successful workflow run.
This artifact contains a list of the built images.
After a successful container image build workflow, another workflow is triggered to [sync the images](#syncing-container-images) to the test Pulp.

In the following example, the user specified a regular expression of `^skydive`, matching all of the Skydive images, and the `base` image that they depend on.

```
REPOSITORY                                                     TAG                       IMAGE ID       CREATED         SIZE
ark.stackhpc.com/stackhpc-dev/centos-source-skydive-agent      wallaby-20220811T091848   32f2b9299194   6 minutes ago   1.29GB
ark.stackhpc.com/stackhpc-dev/centos-source-skydive-analyzer   wallaby-20220811T091848   35e4c1cda1a8   7 minutes ago   1.14GB
ark.stackhpc.com/stackhpc-dev/centos-source-skydive-base       wallaby-20220811T091848   3bd5f3e50aa3   7 minutes ago   1.14GB
ark.stackhpc.com/stackhpc-dev/centos-source-base               wallaby-20220811T091848   bd02fa0ec1d6   7 minutes ago   991MB
```

In this example, the base and Skydive images have been tagged `wallaby-20220811T091848`.

Instructions for building Kolla container images manually are provided in the [StackHPC kayobe config README](https://github.com/stackhpc/stackhpc-kayobe-config/blob/bf1396b8564b79344e4b6cfb934eab865ff1ad09/README.rst#L226).

## Publishing container images

The [Publish container repositories](https://github.com/stackhpc/stackhpc-release-train/actions/workflows/container-publish.yml) workflow runs after a push to the `main` branch of the `stackhpc-release-train` repository, when relevant files have changed.

It runs the following playbooks:

* `dev-pulp-container-publish.yml`: Configure access control for development and release container repositories and distributions on `ark`.

Use GitHub Actions to run this workflow, or to run it manually:

```
ansible-playbook -i ansible/inventory \
ansible/dev-pulp-container-publish.yml
```

Configuration for container images is in:

* [ansible/inventory/group_vars/all/kolla](https://github.com/stackhpc/stackhpc-release-train/blob/main/ansible/inventory/group_vars/all/kolla).
* [ansible/inventory/group_vars/all/dev-pulp-containers](https://github.com/stackhpc/stackhpc-release-train/blob/main/ansible/inventory/group_vars/all/dev-pulp-containers).
* [ansible/inventory/group_vars/all/test-pulp-containers](https://github.com/stackhpc/stackhpc-release-train/blob/main/ansible/inventory/group_vars/all/test-pulp-containers).

New images should be added to `kolla_container_images` in `ansible/inventory/group_vars/all/kolla`.

## Syncing container images

The [Sync container repositories](https://github.com/stackhpc/stackhpc-release-train/actions/workflows/container-sync.yml) workflow runs after a successful [container image build](#building-container-images) workflow run, or on demand.
It runs the following playbooks:

* `test-pulp-container-sync.yml`: Synchronise `test` with container images from `stackhpc-dev` namespace on `ark`.
* `test-pulp-container-publish.yml`: Create distributions on `test` Pulp server for any new container images.

Use GitHub Actions to run this workflow, or to run it manually:

```
ansible-playbook -i ansible/inventory \
ansible/test-pulp-container-sync.yml \
ansible/test-pulp-container-publish.yml
```

## Updating container image tags in Kayobe configuration (Yoga release and earlier)

The image tag used deploy containers may be updated for all images in [etc/kayobe/kolla.yml](https://github.com/stackhpc/stackhpc-kayobe-config/blob/stackhpc/wallaby/etc/kayobe/kolla.yml), or for specific images in [etc/kayobe/kolla/globals.yml](https://github.com/stackhpc/stackhpc-kayobe-config/blob/stackhpc/wallaby/etc/kayobe/kolla/globals.yml).
Currently this is a manual process.

Use the new tag from the [container image build](#building-container-images).

For example, to update the default tag for all images (used where no service-specific tag has been set), update `etc/kayobe/kolla.yml`:

```yaml
# Kolla OpenStack release version. This should be a Docker image tag.
# Default is {{ openstack_release }}.
kolla_openstack_release: wallaby-20220811T091848
```

Some or all per-service tags in `etc/kayobe/kolla/globals.yml` may need to be removed in order to use the new default tag.

Alternatively, to update the tag for all containers in a service, update `etc/kayobe/kolla/globals.yml`:

```yaml
skydive_tag: wallaby-20220811T091848
```

Alternatively, to update the tag for a specific container, update `etc/kayobe/kolla/globals.yml`:

```yaml
skydive_analyzer_tag: wallaby-20220811T091848
```

## Updating container image tags in Kayobe configuration (Zed release onwards)

The image tags used deploy containers are defined in [etc/kayobe/kolla-image-tags.yml](https://github.com/stackhpc/stackhpc-kayobe-config/blob/stackhpc/zed/etc/kayobe/kolla-image-tags.yml).
Currently updating these is a manual process.

Use the new tag from the [container image build](#building-container-images).

For example, to update the default tag for all images (used where no service-specific tag has been set), update the `openstack` key, and remove all other keys:

```yaml
# Dict of Kolla image tags to deploy for each service.
# Each key is the tag variable prefix name, and the value is another dict,
# where the key is the OS distro and the value is the tag to deploy.
kolla_image_tags:
  openstack:
    rocky-9: zed-rocky-9-20230101T000000
    ubuntu-jammy: zed-ubuntu-jammy-20230101T000000
```

Alternatively, update the tag for all containers in a service, e.g. for all `nova` containers:

```yaml
# Dict of Kolla image tags to deploy for each service.
# Each key is the tag variable prefix name, and the value is another dict,
# where the key is the OS distro and the value is the tag to deploy.
kolla_image_tags:
  openstack:
    rocky-9: zed-rocky-9-20230101T000000
    ubuntu-jammy: zed-ubuntu-jammy-20230101T000000
  nova:
    rocky-9: zed-rocky-9-20230102T000000
    ubuntu-jammy: zed-ubuntu-jammy-20230102T000000
```

Alternatively, update the tag for a specific container, e.g. for the `nova_compute` container:

```yaml
# Dict of Kolla image tags to deploy for each service.
# Each key is the tag variable prefix name, and the value is another dict,
# where the key is the OS distro and the value is the tag to deploy.
kolla_image_tags:
  openstack:
    rocky-9: zed-rocky-9-20230101T000000
    ubuntu-jammy: zed-ubuntu-jammy-20230101T000000
  nova_compute:
    rocky-9: zed-rocky-9-20230103T000000
    ubuntu-jammy: zed-ubuntu-jammy-20230103T000000
```

## Promoting container images (Zed release onwards)

!!! note

    This should only be performed when container images are ready for release.

The [Promote container repositories](https://github.com/stackhpc/stackhpc-release-train/actions/workflows/container-promote.yml) workflow is triggered automatically when a change is merged to stackhpc-kayobe-config.
It may also be run on demand.

It runs the following playbooks:

* `dev-pulp-container-tag-query-kayobe.yml`: Query the Pulp container image tags defined in a Kayobe configuration repository and set the tag map variable `dev_pulp_repository_container_promotion_tags` based upon those tags. A path to a Kayobe configuration repository must be specified via `kayobe_config_repo_path`.
* `dev-pulp-container-promote.yml`: Promote a set of container images from `stackhpc-dev` to `stackhpc` namespace. The tags to be promoted are defined via `dev_pulp_repository_container_promotion_tags`.

Use GitHub Actions to run this workflow, or to run it manually:

```
ansible-playbook -i ansible/inventory \
ansible/dev-pulp-container-tag-query-kayobe.yml \
ansible/dev-pulp-container-promote.yml \
-e kayobe_config_repo_path=../stackhpc-kayobe-config/
```

In this example, the Pulp container image tags defined in the `etc/kayobe/kolla-image-tags.yml` file in `../stackhpc-kayobe-config` repository (relative to the current working directory) will be promoted to releases.

## Promoting container images (Yoga release and earlier)

!!! note

    This should only be performed when container images are ready for release.

The [Promote container repositories (old)](https://github.com/stackhpc/stackhpc-release-train/actions/workflows/container-promote-old.yml) workflow runs on demand.
It should be run when container images need to be released, typically after a change to [update container image tags](#updating-container-image-tags-in-kayobe-configuration-yoga-release-and-earlier) has been approved.
It runs the following playbook:

* `dev-pulp-container-promote-old.yml`: Promote a set of container images from `stackhpc-dev` to `stackhpc` namespace. The tag to be promoted is defined via `dev_pulp_repository_container_promotion_tag` which should be specified as an extra variable (`-e`).

Use GitHub Actions to run this workflow, or to run it manually:

```
ansible-playbook -i ansible/inventory \
ansible/dev-pulp-container-promote-old.yml
```

## Other utilities

* `dev-pulp-distribution-list.yml`: List available distributions in `ark`.
* `test-pulp-distribution-list.yml`: List available distributions in `test`.
* `test-repo-test.yml`: Install package repositories on the local machine and install some packages.
