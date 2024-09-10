# StackHPC Release Train

The StackHPC release train is a mechanism to provide tested, reproducible software releases for our supported clients.
This site provides documentation for the StackHPC release train, covering this and other related repositories, as well as the services that comprise the live system.

## Background

The CentOS 8 Stream announcement has caused us to do something we knew we wanted to do anyway (but had never got around to).
We must provide a method for tested and reproducible releases for our supported clients.
A related goal is to minimise unnecessary divergence between configuration of client deployments.

## Aim

The ultimate aim of the release train is to provide tested and reproducible software releases.
This includes artifacts, metadata, and the configuration necessary to consume them.

## Scope

The current scope of the release train covers OpenStack control plane deployment, and all the dependencies thereof.
This includes:

* Host Operating System (OS) repositories, e.g. Rocky Linux 9 BaseOS
* Source code repositories
* Kolla container images
* Ironic Python Agent (IPA) deployment images
* VM & bare metal disk images

In future, the scope may expand to cover other software, such as Kubernetes.

## Configuration

StackHPC provides a [base Kayobe configuration](https://github.com/stackhpc/stackhpc-kayobe-config) which includes settings required to consume the release train.
Clients merge this configuration into their own, and apply site and environment-specific changes.

## Hosting and accessing content

The release train artifacts are hosted via [Pulp](https://pulpproject.org/) at <https://ark.stackhpc.com>.
Access to the API and artifacts is controlled via client user account passwords.
Clients deploy a local Pulp service which syncs with Ark.

## Automation & Continuous Integration (CI)

Automation and CI are key aspects of the release train.
The additional control provided by the release train comes at a cost in maintenance and complexity, which must be offset via automation and CI.
Leveraging technologies such as; [Ansible](https://www.ansible.com/) and [Terraform](https://www.terraform.io/) in addition to services such as [Github Workflows](https://github.com/features/actions) allows us to achieve the goals of the StackHPC release train.
There are numerous applications of these aforementioned technologies and services across various repositories within the StackHPC organisation, they are as follows;
