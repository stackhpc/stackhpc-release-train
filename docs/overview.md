# Overview

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

* Host Operating System (OS) repositories, e.g. CentOS Stream 8 BaseOS
* Kolla container images
* Ironic Python Agent (IPA) deployment images
* VM & bare metal disk images

Initially, only CentOS Stream 8 is supported as a host and container OS.
Ubuntu support will follow.

In future, the scope may expand to cover other software, such as Kubeternetes.

## Configuration

StackHPC provides a [base Kayobe configuration](https://github.com/stackhpc/stackhpc-kayobe-config) which includes settings required to consume the release train.
Clients merge this configuration into their own, and apply site and environment-specific changes.

## Hosting and accessing content

The release train artifacts are hosted via [Pulp](https://pulpproject.org/) at <https://ark.stackhpc.com>.
Access to the API and artifacts is controlled via client certificates and passwords.
Clients deploy a local Pulp service which syncs with Ark.

## Automation & Continuous Integration (CI)

Automation and CI are key aspects of the release train.
The additional control provided by the release train comes at a cost in maintainence and complexity, which must be offset via automation and CI.
In general, Ansible is used for automation, and Github Actions provide CI.
