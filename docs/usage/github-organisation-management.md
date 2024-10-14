# Usage - GitHub Organisation Management

With the the ever growing number of repositories related to StackHPC Release Train, it is important that we can manage all of the repositories in an automated manner.
To achieve this we have opted to use [Terraform](https://www.terraform.io/) and its [GitHub Provider](https://registry.terraform.io/providers/integrations/github/latest/docs) to automate the configuration of StackHPC's [GitHub profile](https://github.com/stackhpc/) and [repositories](https://github.com/orgs/stackhpc/repositories).

By using Terraform's GitHub Provider we can configure various aspects of GitHub ranging from enforcing branch protection rules across repositories, creating teams and assigning members in addition to configuring how pull requests (PRs) are reviewed and merged.

The Terraform configuration can be found within the [stackhpc-release-train](https://github.com/stackhpc/stackhpc-release-train) repository under `terraform/github`.
It is expected that all `plans` and `applies` are carried out within GitHub Actions where the `statefile` is stored within [Terraform Cloud](https://cloud.hashicorp.com/products/terraform).

!!! note

    Access to Terraform Cloud is limited due to team size restrictions if you need access to Terraform Cloud and don't have access already then feel free to request access in the appropriate Slack channel.

GitHub authentication is handled using a GitHub app.

## Making Changes

In this section we shall look at how you may modify the Terraform configuration to suit your needs and requirements.
This will not cover how to increase the use of the GitHub Provider to configure others elements of the organisation.
However, if you need to use additional parts of the provider please consult the provider's [documention](https://registry.terraform.io/providers/integrations/github/latest/docs).

### Import, Plan & Apply

!!! note

    Terraform by default will attempt to delete resources that are contained within its statefile yet no longer represented in the plan.
    This is not ideal for the use case of managing repositories.
    Therefore, `lifecycle prevent destroy` has been applied to all resources within this configuration.
    This will cause any plan that attempts to delete a resource to fail.
    Therefore, if you have a reason to remove and delete something such as team member then this must be done as described in _Removing Resources_

The workflow for altering the configuration is as follows; 

1. Make the change to `terraform.tfvars.json` and potentially one of the `.tf` files

2. Open a PR which shall trigger a GitHub workflow which shall produce a plan detailing the changes Terraform shall make

3. Review the changes

4. If any of the changes involve _adopting_ an existing repository or team then you must run `terraform_github_import.yml`, see below for details

5. If you do import existing resources then you must produce a new plan which currently can achieved by closing the PR and reopening it

6. Merge once the PR has been approved this will trigger `terraform-github.yml` to perform the `apply`

### Importing Resources

Whilst Terraform is capable of creating resources it is expected that a lot of the resources already exist and therefore need to be imported before Terraform can apply the configuration rules.
To import a resource we have made available a convenient GitHub Workflow called `Terrform GitHub Import` which will identify what resources are referenced within the `configuration` and are missing from the `statefile`.

To use the workflow you will navigate to [`Terraform GitHub Import`](https://github.com/stackhpc/stackhpc-release-train/actions/workflows/terraform-github-import.yml) under the`Actions` tab for stackhpc-release-train.
Once there you can manually dispatch a workflow where you must specify the branch for which the workflow will run from this should be the branch that has an open PR for.
Also you can specify if the import should perform a dry run to provide reassurance before making actually changes to the statefile.
You must run the workflow again with `Dry Run` unticked.

!!! warning

    As we currently use one workspace to manage the `statefile` it can lead to difficulties when attempting to make multiple changes across different PRs.
    Therefore, it is currently recommended that merges are made shortly after an import has taken place.
    Otherwise it will negatively impact the plans produced due to conflicts between statefile and the various configurations.
    Also note that if an import has been carried in error then you must make sure to remove that from the statefile which can achieved using the instructions found in _Removing Resources_


### Adding Member to Team

To add a member to a team you must add the new member's `username` to the the `users` object within the specific team within `teams` object.
Majority of users can be placed within the `members` object however certain users such as those that are administrators of the organisation must be placed within the `maintainers` object.
Also either the `maintainers` or `members` must contain at least one entry this is due to a limitation of the provider.
A fix would be to include `stackhpc-ci` if there is currently no one in the team.

*<sub><sup>terraform/github/terraform.tfvars.json</sup></sub>*
```yml 
"Batch": {
  "description": "Team responsible for Batch development",
  "privacy": "closed",
  "users": {
    "maintainers": [],
    "members": [
      "jackhodgkiss" # New user added to team
    ]
  }
}
```

### Adding Repository to Team

To add a repository to a team you can append the name of the repository to the desired team within the `repositories` object.

*<sub><sup>terraform/github/terraform.tfvars.json</sup></sub>*
```yml 
"repositories": {
  "Ansible": [
    "ansible-role-os-networks",
    ...
    "ansible-collection-pulp",
    "ansible-collection-hashicorp",
    "ansible-collection-openstack-ops",
    "ansible-role-vxlan" # New repository added to team
]
```

### Removing Resources

To remove a resource you must first identify and delete the entry from within `terraform.tfvars.json`.
Once done you can open a PR which will trigger the `terrform-github` workflow which will most likely return an error due to the attempt to delete the resource via Terraform being block by the `lifecycle prevent_destroy` attribute.
To resolve this issue you will need access to the Terraform Cloud GitHub workspace, if you don't have access then you may request access or have someone who does have access to perform the removal on your behalf.

Prior to remove a resource you must ensure that you have the Terraform CLI tools and have authenticated with Terraform Cloud, instructions for this can be found [here](https://www.terraform.io/cli/commands/login).
The steps for removing a resource such as the `ansible-role-vxlan` for the `Ansible` team are as follows;

```sh
git clone git@github.com:stackhpc/stackhpc-release-train.git
cd stackhpc-release-train/terraform/github
terraform state rm 'github_branch_protection.ansible_branch_protection["ansible-role-vxlan"]'
```

The general form for `state rm` is `${resource_address}["resource_id"]`.
You can found out more about the `state rm` command here [here](https://www.terraform.io/cli/commands/state/rm).
You may also find documentation about the GitHub provider which may provide insight into how the resources are composed [here](https://registry.terraform.io/providers/integrations/github/latest/docs)

### Renaming Resources

To rename a resource you must first identify and rename the entry within `terraform.tfvars.json`.
Without further intervention Terraform will see this as deletion of one resource and creation of another, and would typically return a failure when trying to create the resource that already exists.
To resolve this issue you will need access to the Terraform Cloud GitHub workspace, if you don't have access then you may request access or have someone who does have access to perform the rename on your behalf.

Prior to renaming a resource you must ensure that you have the Terraform CLI tools and have authenticated with Terraform Cloud, instructions for this can be found [here](https://www.terraform.io/cli/commands/login).

In the following example we will rename the `ansible-role-os-networks` repository to `os-networks`.

Clone this repository and change to the `terraform/github` directory:

```sh
git clone git@github.com:stackhpc/stackhpc-release-train.git
cd stackhpc-release-train/terraform/github
```

Rename the `ansible-role-os-networks` entry in `terraform.tfvars.json`.
Commit the change and push to a branch on GitHub.

Create a script named `rename-repo.sh` with the following content:

```sh
#!/bin/bash -eux

repo_src=${1:?Repo source}
repo_dst=${2:?Repo destination}

# e.g. -dry-run
args=""

# This resource list will vary depending on the repository.
# In particurlar this may include the branch protection and team associations.
resources="github_branch_protection.ansible_branch_protection \
github_issue_label.community_files_label \
github_issue_label.stackhpc_ci_label \
github_issue_label.workflows_label \
github_team_repository.admin_repositories \
github_team_repository.ansible_repositories \
github_team_repository.developers_repositories \
github_repository.repositories"

for resource in $resources; do
  terraform state mv $args "$resource[\"$repo_src\"]" "$resource[\"$repo_dst\"]"
done
```

Edit the `resources` list based on the output of `terraform state list | grep <repo>`

Make the script executable:

```sh
chmod +x rename-repo.sh
```

Run the script to rename the repository. Note that this will directly update the state file in Terraform cloud:

```sh
./rename-repo.sh ansible-role-os-networks os-networks
```

Create a PR for the changes.

## StackHPC Release Train TF bot

GitHub authentication is handled using the [StackHPC Release Train TF bot App](https://github.com/organizations/stackhpc/settings/apps/stackhpc-release-train-tf-bot).
This app has a private key that is registered as a [GitHub secret](secrets.md).
The app is [installed](https://github.com/organizations/stackhpc/settings/installations/27194723) on the `stackhpc` organisation, with access to all repositories.
It has only the necessary permissions, but these are rather broad.
GitHub apps are documented [here](https://docs.github.com/en/apps/overview).
