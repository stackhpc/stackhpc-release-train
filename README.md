# StackHPC Release Train

StackHPC release automation

## Installation

```
python3 -m venv venv
source venv/bin/activate
pip install -U pip
pip install -r requirements.txt
ansible-galaxy collection install -r requirements.yml -p ansible/collections
```

## Prerequisites

A Pulp server should be running.

The following procedure can be used to spin up a [Pulp in
one](https://pulpproject.org/pulp-in-one-container/) 3.11 container.

Why are we using Pulp 3.11? The latest versions of the pulp-rpm plugin have a
[bug](https://pulp.plan.io/issues/8622) breaks some dependencies in CentOS
repos. Some
[discussion](https://app.element.io/?pk_vid=44f328f723e826ef1625565250e6a7ed#/room/#pulp-rpm:matrix.org)
on the matrix channel.

```
sudo dnf -y install git vim tmux
sudo dnf -y install podman
mkdir settings pulp_storage pgsql containers
echo "CONTENT_ORIGIN='http://$(hostname):8080'
ANSIBLE_API_HOSTNAME='http://$(hostname):8080'
ANSIBLE_CONTENT_HOSTNAME='http://$(hostname):8080/pulp/content'
TOKEN_AUTH_DISABLED=True" >> settings/settings.py
podman run --detach              --publish 8080:80              --name pulp              --volume "$(pwd)/settings":/etc/pulp              --volume "$(pwd)/pulp_storage":/var/lib/pulp              --volume "$(pwd)/pgsql":/var/lib/pgsql              --volume "$(pwd)/containers":/var/lib/containers              --device /dev/fuse              pulp/pulp:3.11
```

Then set an admin password:

```
podman exec -it pulp bash -c 'pulpcore-manager reset-admin-password'
```

Install a client:

```
sudo dnf -y install python3-pip
pip3 install pulp-cli[pygments] --user
pulp config create --username admin --base-url http://localhost:8080 --password <password>
pulp status
```

There is a [bug](https://pulp.plan.io/issues/8807) in the pulp-rpm plugin
shipped in the Pulp 3.11 container meaning that it does not work out of the
box. Fix it up:

```
podman exec -it pulp bash
pip install --no-deps 'productmd<1.33'
cd  /var/run/s6/services
s6-svc -r new-pulpcore-worker@1
s6-svc -r new-pulpcore-worker@2
s6-svc -r pulpcore-api
s6-svc -r pulpcore-content
s6-svc -r pulpcore-resource-manager
s6-svc -r pulpcore-worker@1
s6-svc -r pulpcore-worker@2
exit
```

## Usage

Set the Pulp admin password:
```
export PULP_PASSWORD=<password>
```

Sync upstream repos.
```
ansible-playbook -i ansible/inventory ansible/pulp-repo-sync.yml
```

Publish repository versions & create distributions.
```
ansible-playbook -i ansible/inventory ansible/pulp-repo-publish.yml
```
