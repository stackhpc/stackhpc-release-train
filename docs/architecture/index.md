# Architecture

This page covers architecture of the StackHPC release train.
It assumes familiarity with the [overview](../index.md).

See the original [release train design document](https://docs.google.com/document/d/1cESuaJg1Zfnj8ZohH8ObeEfF8ay14wWe1YFGer3k10Q/edit) for design & requirements.

## Components

The following diagram shows the major components of the release train.

![Release train components](../img/components.png)

This diagram was created using [Google Drawings](https://docs.google.com/drawings/d/1gVssWRoFJPapv7K819zfceSobW4PABFJO4PT7IufGSQ/edit).

## Pulps

[Pulp](https://pulpproject.org) is a content server that manages repositories of software packages and facilitates their distribution to content consumers.
The core functionality of Pulp is to provide versioned collections of software packages for onward distribution to consumers.
Pulp's ability to host multiple snapshots of a repository make it a good choice for hosting the release train content.

There are three types of Pulp service in the release train architecture.

* [Ark](https://ark.stackhpc.com) is a public-facing production Pulp service hosted on a public cloud provider, [leaf.cloud](https://www.leaf.cloud/).
  It is the master copy of development and released content, and makes the content available to clients.

* Clients access Ark via a Pulp service deployed on their local infrastructure.
  Content is synced from Ark to the local Pulp service, and control plane hosts acquire the content from there.

* [Test](http://pulp-server.internal.sms-cloud) is an internal service running on the SMS lab cloud.
  Content is synced from Ark to `test`, providing a local content mirror for testing in SMS lab.
  In some respects, the test Pulp service may be considered a client.

## Content

Various different types of content are hosted by Pulp, including:

* RPM package repositories ([Pulp RPM plugin](https://docs.pulpproject.org/pulp_rpm/))
    * CentOS distribution packages
    * Third party packages
* Container image repositories ([Pulp container plugin](https://docs.pulpproject.org/pulp_container/))
    * Kolla container images

We also anticipate supporting the following content:

* Apt package repositories ([Pulp Deb plugin](https://docs.pulpproject.org/pulp_deb/))
    * Ubuntu distribution packages
    * Third party packages
* File repositories ([Pulp file plugin](https://docs.pulpproject.org/pulp_file/))
    * Disk images

Some of this content may be mirrored from upstream sources, while others are the result of release train build processes.

## Access control

Access to released Pulp content is restricted to clients with a support agreement.
Build and test processes also need access to content.

### Package repositories

Access to package repositories is controlled via [Pulp x509 cert guards](https://docs.pulpproject.org/pulp_certguard/).
A [Hashicorp Vault](https://vault.stackhpc.com/) service acts as a Certificate Authority (CA) for the cert guards.
Two cert guards are in use - `development` and `release`.
The `development` cert guard is assigned to unreleased content, while the `release` cert guard is assigned to released content.
Clients are provided with a client certificate which they use when syncing package repositories in their local Pulp service with Ark.
Clients' client certificates are authorised to access content protected by the `release` cert guard.
Build and test processes are provided with client certificate that is authorised to access the `development` and `release` cert guard.
The latter is made possible via the CA chain.

### Containers

Access to container images is controlled by token authentication, which uses Django users in the backend.
Two container namespaces are in use - `stackhpc-dev` and `stackhpc`.
The `stackhpc-dev` namespace is used for unreleased content, while the `stackhpc` namespace is used for released content.
Clients are provided with a set of credentials, which they use when syncing container image repositories in their local Pulp service with Ark.
Clients' credentials are authorised to pull from the `stackhpc` namespace.
Build and test processes are provided with credentials that are authorised to push to the `stackhpc-dev` namespace.

## Syncing package repositories

At the top of the diagram above are the upstream sources.
Some of these may be mirrored/synced into Ark, including:

* OS distribution package repositories, e.g. CentOS Stream 8 BaseOS
* Third party package repositories, e.g. Grafana

The [Sync package repositories](https://github.com/stackhpc/stackhpc-release-train/actions/workflows/package-sync.yml) Github Actions workflow runs nightly and on demand, ensuring that we have regular versioned snapshots of these repositories.
Synced content is immediately published and distributed, such that it is available to build & test processes.
After a successful sync in Ark, the content is synced to the test Pulp service.

Mirrored content typically uses a [policy](https://docs.pulpproject.org/pulpcore/workflows/on-demand-downloading.html) of `immediate`, meaning that all content is downloaded from the upstream source during the sync.
This avoids issues seen with the `on_demand` policy where content that is removed from the upstream source becomes inaccessible if it has not been previously requested by a client.
For RPM content, we also use a [sync_policy](https://docs.pulpproject.org/pulp_rpm/workflows/create_sync_publish.html#sync-repository-foo-using-remote-bar) of `mirror_complete`, which removes content from the snapshots in line with upstream repositories (in contrast with the default `additive` `sync_policy`, which does not).
There are a couple of repositories for which `mirror_complete` does not work, so we use `mirror_content_only` instead.

### Versioning

Package repositories are versioned based on the date/time stamp at the beginning of the sync workflow, e.g. `20211122T102435`.
This version string is used as the final component of the path at which the corresponding distribution is hosted.
For example, a CentOS Stream 8 BaseOS snapshot may be hosted at https://ark.stackhpc.com/pulp/content/centos/8-stream/BaseOS/x86_64/os/20220105T044843/.

The rationale behind using a date/time stamp is that there is no sane way to version a large collection of content, such as a repository, in a way in which the version reflects changes in the content (e.g. SemVer).
While the timestamp used is fairly arbitrary, it does at least provide a reasonable guarantee of ordering, and is easily automated.

## Building

Build processes may take as input the synced repository mirrors and other external sources, including:

* Python Package Index (PyPI)
* StackHPC source code repositories
* Other source code repositories e.g. Github, OpenDev

The outputs of these build processes are pushed to Ark.

Build and test processes run on SMS cloud, to avoid excessive running costs.
All content in Ark that is required by the build and test processes is synced to the test Pulp service running in SMS cloud, minimising data egress from Ark.

### Kolla container images

Kolla container images are built via Kayobe, using a `builder` environment in [StackHPC Kayobe config](https://github.com/stackhpc/stackhpc-kayobe-config).
The configuration uses the package repositories in Ark when building containers.
Currently this is run manually, but will eventually run as a CI job.
The `stackhpc-dev` namespace in Ark contains [container push repositories](https://docs.pulpproject.org/pulp_container/workflows/push.html), which are pushed to using Kayobe.
Currently this is rather slow due to a [Pulp bug](https://github.com/pulp/pulp_container/issues/494).

The [Sync container repositories](https://github.com/stackhpc/stackhpc-release-train/actions/workflows/container-sync.yml) Github Actions workflow runs demand, syncing container repositories in test Pulp service with those in Ark.
It also configures container image distributions to be private, since they are public by default.

Kolla container images are versioned based on the OpenStack release name and the date/time stamp at the beginning of the build workflow, e.g. `wallaby-20211122T102435`.
This version string is used as the image tag.
Unlike package repositories, container image tags allow multiple versions to be present in a distribution of a container repository simultaneously.
We therefore use separate namespaces for development (`stackhpc-dev`) and release (`stackhpc`).

### Disk images

Disk images are currently not built by the release train.

## Testing

Release train content is tested via a Kayobe deployment of OpenStack.
An `aio` environment in [StackHPC Kayobe config](https://github.com/stackhpc/stackhpc-kayobe-config) provides a converged control/compute host for testing.
Currently this is run manually, but will eventually run as a CI job.

## Promotion

Whether content is mirrored from an upstream source or built locally, it is not immediately released.
Promotion describes the process whereby release candidate content is made into a release that is available to clients.

For package repositories, promotion does not affect how content is accessed, only who may access it.
Promotion involves changing the content guard for the distribution to be released from `development` to `release`.
This makes the content accessible to clients using their x.509 client certificates.

The `stackhpc` container namespace contains regular container repositories, which cannot be pushed to via `docker push`.
Instead, we use the Pulp API to sync specific tags from `stackhpc-dev` to `stackhpc`.

## Client Pulp service

Clients access Ark via a Pulp service deployed on their local infrastructure.
Typically the Pulp service is deployed as a [Pulp in one](https://pulpproject.org/pulp-in-one-container/) container running on the seed host.
Content is synced from Ark to the local Pulp service, and control plane hosts acquire the content from there.
This avoids excessive Internet bandwidth usage, both for the client and Ark.

Content in the client Pulp service is synced using the `on_demand` policy.
This avoids unnecessarily large storage requirements on the seed, and speeds up syncing.
There should be no risk of content becoming permantently unavailable, so long as Ark continues to host sufficiently old versions.
This approach does have a downside of requiring Ark to be available to provide any content which has not previously been downloaded.

## Client configuration

In order to consume the release train, clients should migrate to [StackHPC Kayobe config](https://github.com/stackhpc/stackhpc-kayobe-config).
This repository provides configuration and playbooks to:

* deploy a local Pulp service as a container on the seed
* package repository versions to use
* container image tags to use
* sync all necessary content from Ark into the local Pulp service
* use the local Pulp repository mirrors on control plane hosts
* use the local Pulp container registry on control plane hosts

This configuration is in active development and is expected to evolve over the coming releases.

Further documentation of this configuration is out of scope here, but is available in the [readme](https://github.com/stackhpc/stackhpc-kayobe-config/blob/stackhpc/wallaby/README.rst).

## Continuous Integration (CI) and automation

The intention is to have as much as possible of the release train automated and run via CI.
Typically, workflows may go through the following stages as they evolve:

1. automated via Ansible, manually executed
1. executed by Github Actions workflows, manually triggered by [workflow dispatch](https://docs.github.com/en/actions/learn-github-actions/events-that-trigger-workflows#workflow_dispatch) or [schedule](https://docs.github.com/en/actions/learn-github-actions/events-that-trigger-workflows#schedule)
1. executed by Github Actions workflows, automatically triggered by an event e.g. pull request or another workflow

This sequence discourages putting too much automation into the Github Actions workflows, ensuring it is possible to run them manually.

The release train Ansible playbooks make heavy use of the [stackhpc.pulp](https://github.com/stackhpc/ansible-collection-pulp) collection, which in turn uses modules from the [pulp.squeezer](https://github.com/pulp/squeezer/) collection.
