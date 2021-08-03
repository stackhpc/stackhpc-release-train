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
one](https://pulpproject.org/pulp-in-one-container/) container.

```
sudo dnf -y install git vim tmux
sudo dnf -y install podman
mkdir settings pulp_storage pgsql containers
echo "CONTENT_ORIGIN='http://$(hostname):8080'
ANSIBLE_API_HOSTNAME='http://$(hostname):8080'
ANSIBLE_CONTENT_HOSTNAME='http://$(hostname):8080/pulp/content'
TOKEN_AUTH_DISABLED=True" >> settings/settings.py
podman run --detach              --publish 8080:80              --name pulp              --volume "$(pwd)/settings":/etc/pulp              --volume "$(pwd)/pulp_storage":/var/lib/pulp              --volume "$(pwd)/pgsql":/var/lib/pgsql              --volume "$(pwd)/containers":/var/lib/containers              --device /dev/fuse              pulp/pulp:latest
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
