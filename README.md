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

## Usage

Set the admin password:
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
