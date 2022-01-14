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

Information on the different playbooks is available in the [release train documentation](https://stackhpc.github.io/stackhpc-release-train/usage/).
