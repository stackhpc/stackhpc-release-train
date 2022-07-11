# StackHPC Release Train

StackHPC release automation

Release train documentation is available at https://stackhpc.github.io/stackhpc-release-train/.

## Installation

On Ubuntu:
```
sudo apt update
sudo apt -y install python3-venv
```

Then create a virtual environment and install Python and Ansible dependencies:

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
```

On Ubuntu:

```
sudo apt -y install python3-pip
```

Then:
```
pip3 install pulp-cli[pygments] --user
pulp config create --username admin --base-url http://<pulp server>:8080 --password <password>
pulp status
```

If using Debian repositories,
```
pip3 install pulp-cli-deb --user
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
