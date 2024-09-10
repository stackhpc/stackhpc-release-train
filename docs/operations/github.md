# Operations - GitHub

## GitHub Actions Runner Controller (ARC)

Some GitHub Actions workflows run on public runners, while others require access to specific services or benefit from data locality.
In the latter case we use GitHub's Actions Runner Controller (ARC) (not to be confused with our Ark...) to provide dynamically scaling containerised private GitHub Actions runners.
The [ARC-Installer](https://github.com/stackhpc/ARC-Installer) repository contains scripts and Helm `values.yaml` configuration for registering the ARC controller services and runner scale sets.
Any project that wishes to use runners on this cluster should define its runner scale set configuration in the ARC-Installer repository.

## [LEGACY] GitHub Actions runners

*We are no longer using this approach, but it is retained in case it is useful in future.*

This Terraform configuration deploys a GitHub Actions runner VMs on an
OpenStack cloud for the stackhpc-release-train repository.

### Usage

These instructions show how to use this Terraform configuration
manually. They assume you are running an Ubuntu host that will be used
to run Terraform. The machine should have network access to the VM that
will be created by this configuration.

Install Terraform:

```
wget -qO - terraform.gpg https://apt.releases.hashicorp.com/gpg | sudo gpg --dearmor -o /usr/share/keyrings/terraform-archive-keyring.gpg
sudo echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/terraform-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/terraform.list
sudo apt update
sudo apt install terraform
```

Clone and initialise the repo:

```
git clone https://github.com/stackhpc/stackhpc-release-train
cd stackhpc-release-train
```

Change to the `terraform/github-runners` directory:

```
cd terraform/github-runners
```

Initialise Terraform:

```
terraform init
```

Create an OpenStack `clouds.yaml` file with your credentials to access an
OpenStack cloud. Alternatively, download one from Horizon. The
credentials should be scoped to the `stackhpc-release` project.

```
cat << EOF > clouds.yaml
---
clouds:
  sms-lab:
    auth:
      auth_url: https://api.sms-lab.cloud:5000
      username: <username>
      project_name: stackhpc-release
      domain_name: default
    interface: public
EOF
```

Export environment variables to use the correct cloud and provide a
password:

```
export OS_CLOUD=sms-lab
read -p OS_PASSWORD -s OS_PASSWORD
export OS_PASSWORD
```

Verify that the Terraform variables in `terraform.tfvars` are correct.

Generate a plan:

```
terraform plan
```

Apply the changes:

```
terraform apply -auto-approve
```

Create a virtualenv:

```
python3 -m venv venv
```

Activate the virtualenv:

```
source venv/bin/activate
```

Install Python dependencies:

```
pip install -r ansible/requirements.txt
```

Install Ansible Galaxy dependencies:

```
ansible-galaxy collection install -r ansible/requirements.yml
ansible-galaxy role install -r ansible/requirements.yml
```

Create a GitHub PAT token (classic) with repo:all scope. Export an
environment variable with the token.

```
read -p PERSONAL_ACCESS_TOKEN -s PERSONAL_ACCESS_TOKEN
export PERSONAL_ACCESS_TOKEN
```

Deploy runners:

```
ansible-playbook ansible/site.yml -i ansible/inventory.yml
```

To remove runners:

```
ansible-playbook ansible/site.yml -i ansible/inventory.yml -e runner_state=absent
```

### Troubleshooting

#### Install service fails

If you see the following:

```
TASK [monolithprojects.github_actions_runner : Install service] ********************************************************************************************************************************************
fatal: [10.205.0.50]: FAILED! => changed=true
  cmd: ./svc.sh install ubuntu
  msg: '[Errno 2] No such file or directory: b''./svc.sh'''
  rc: 2
  stderr: ''
  stderr_lines: <omitted>
  stdout: ''
  stdout_lines: <omitted>
```

It might mean the runner is already registered, possibly from a previous
VM. Remove the runner using Ansible or the GitHub settings.
