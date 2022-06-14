# Usage - source code continuous integration

Source code continuous integration (CI) is handled by Github Workflows.
There are currently three workflows in use, whose objective is to perform tedious tasks or to ensure that the code is correct and style guidelines are being followed.
A brief overview of these workflows was given in the [Overview Section](../index.md#github-actions) whereas this section will provide additional insight into how these workflows function and how you can modify these workflows. 
Also discussed are the community files used by Github to improve developer experience within the respositories in addition to how we intend to synchronise all of the source code repositories with latests files.

## Github Workflows

This section is simply intended to document the behaviour of these workflows actual modification should be handled via the Synchronise Repositories Playbook which is documented below in [Synchronise Repositories Playbook Section](#synchronise-repositories-playbook).
The table below contains the different workflows with a description of each and the project type they would are used within.

| Workflow               | Description                                                                                 | Project Type         |
| :--------------------: | ------------------------------------------------------------------------------------------- | :------------------: |
| **Upstream Sync**      | Keep our downstream fork up-to-date with the upstream counterpart                           | OpenStack            |
| **Tag & Release**      | Generate an new tag and accompanying release whenever a commit is pushed to select branches | OpenStack            |
| **Tox**                | Perform linting and unit testing                                                            | OpenStack            |
| **Publish Role**       | Publish the Ansible Role on Ansible Galaxy                                                  | Ansible (Role)       |
| **Publish Collection** | Publish the Ansible Collection on Ansible Galaxy                                            | Ansible (Collection) |

!!! info "Reusable Workflow Location"

    The following workflows are setup as [reusable workflows](https://docs.github.com/en/actions/using-workflows/reusing-workflows) and can be found within the [StackHPC/.github](https://github.com/stackhpc/.github/tree/main/.github/workflows) repository. The advantage of this approach means that changes to a given workflow can be made in one place rather than each repository individualy.

### Tox

OpenStack use [Tox](https://wiki.openstack.org/wiki/Testing) to manage the unit tests and style checks for the various projects they maintain.
Therefore, when a `pull request` is opened the tox workflow will automatically perform a series of unit tests and linting in order ensure correctness and style guidelines are being met.
The workflow will run in both python 3.6 and python 3.8 environments.
This can be controlled within the strategy matrix of the workflow. 
The Python versions should correspond to those used in the supported OS distributions for a particular release.

```yaml
strategy:
  matrix:
    include:
      - environment: py36
        python-version: 3.6
      - environment: py38
        python-version: 3.8
      - environment: pep8
        python-version: 3.8
```

### Tag & Release

Software that depends on the source code repositories that the Release Train manages, typically will use a tag to identify the particular release to download and use.
Therefore, to automate the process this workflow will generate a new tag for the latest commit to `stackhpc/**` which in turn will publish a new release under the given repository's Releases page.

!!! Warning
    
    The tag format currently used by this workflow is `stackhpc/a.b.c.d` which is **NOT** [SemVer](https://semver.org/) compliant and cannot be used in certain circumstances such as within [Helm Charts](https://helm.sh/docs/chart_best_practices/conventions/#version-numbers).
    However, for the needs of the Release Train this is adequate.

### Upstream Sync

Since many of our repositories are forked from OpenStack we need to ensure that we remain in sync with upstream in order to prevent situations where we deviate which could make any future attempts more difficult than it should be.
Therefore, this workflow will periodically check if our `stackhpc/**` are behind their OpenStack counterparts.
If so the workflow will copy the OpenStack branch into the repository and then make a `pull request` off of this copy ready to merge pending review by the relevant codeowner. 
Since the workflow uses the [Github REST API](https://docs.github.com/en/rest) it will still be able to open a PR even if it would result in a merge conflict allowing the relevant codeowner to make the necessary changes to resolve such a conflict.
The workflow can be triggered manually within the `Actions` tab of a repository in addition to being scheduled to automatically.
Currently is scheduled to run once a week on **Monday at 09:15AM BST**.
This can be changed in the [workflow template within the .github repository](https://github.com/stackhpc/.github/blob/main/workflow-templates/upstream-sync.yml). As the workflow scheduled it must be located within the `default branch` such as `main` or `master` for Github to register it.

```yaml
'on':
  schedule:
    - cron: '15 8 * * 1'
  workflow_dispatch:
```

### Publish Collection/Role

These two workflow automate the publication of a Ansible Collection or Role to Ansible Galaxy. They can triggered either manually or whenever a new tag is pushed in the form `v[0-9]+.[0-9]+.[0-9]+` for a collection or `v?[0-9]+.[0-9]+.[0-9]+` for a role.

## Synchronise Repositories Playbook

Whilst the workflows can be imported manually this is **NOT** the intended approach, rather we will use an Ansible Playbook responsible for identifying repositories that are out of sync or missing the required files and perform pull requests to bring them inline.
The playbook and role called `source-repo-sync` is located within [this repository](https://github.com/stackhpc/stackhpc-release-train/tree/main/ansible/roles/source-repo-sync) and will run inside of a Github Workflow, whenever a change is made to the configuration or variables.
The motivation behind this is to have single-source of truth and free up developer time as creating dozens of branches and pull requests can be quite monotonous.

### Making modifications to the playbook

!!! info "Source Repositories Vars"

    * **default_releases**: list of OpenStack release series currently supported by StackHPC and used within the workflows
    * **openstack_workflows**: dictionary of OpenStack specific workflows as mentioned above
        * default_branch_only: list of workflows that will only exist on the `default branch` **(master/main)**
        * elsewhere: list of workflows that will be placed on other branches such as `stackhpc/xena` see `default_releases`
    * **ansible_workflows**: dictionary contain either the type of Ansible `collection` or `role`
        * collection: list of workflows specific to Ansible collections
        * role: list of workflows specific to Ansible roles
    * **source_repositories**: dictionary of repositories targeted by the Ansible playbook
        * repository_name: points to repository, must match the name of the repository exactly.
            * repository_type: used to distinguish if the repository is OpenStack or Ansible related, defaults to OpenStack if not provided
            * workflows: can either use `openstack_workflows`, `ansible_workflows` or provide a custom set of workflows, see ** below! **

    ```yaml
    ---
    default_releases:
      - xena
      - wallaby
      - victoria
    openstack_workflows:
      default_branch_only:
        - upstream-sync
      elsewhere:
        - tox
        - tag-and-release
    ansible_workflows:
      collection:
        - publish_collection
      role:
        - publish_role
    source_repositories:
      kolla:
        workflows: '{{ openstack_workflows }}'
      ansible-collection-pulp:
        repository_type: 'ansible'
        workflows: '{{ ansible_workflows.collection }}'
    ```

In this subsection we shall explore how to make various modifications to the playbook. 
Please review the `Source Repositories Vars` for a description of the variables found within [source-repositories](https://github.com/stackhpc/stackhpc-release-train/blob/main/ansible/inventory/group_vars/all/source-repositories) vars file.

!!! note

    Modifications can be made either by clone the stackhpc-release-train repository locally or using the [Github Dev Editor](https://github.dev/github/dev) by pressing `.` key within the repository.

#### Changing the release series

To change the release series for all OpenStack repositories this can be achived by editing the `default_releases` variable.
For example if you wanted to remove victoria and add support for yoga.
Once this change has been merged into the `main` branch it shall perform a series of pull requests updating the workflows across all listed repositories.

!!! note "ansible/inventory/group_vars/all/source-repositories"

    ```yaml
    ---
    default_releases:
      - xena
      - wallaby
      - victoria
    ```

    ```yaml
    ---
    default_releases:
      - yoga
      - xena
      - wallaby
    ```

#### Adding new workflows

It is more involved to add additional workflows for distribution across the repositories. 

1. Add the workflow to the `.github` repository as one that is reusable.

2. Add the workflow caller as Jinja template in the folder `ansible/roles/source-repo-sync/templates` such as `deploy.jinja`

3. Update `ansible/inventory/group_vars/all/source-repositories` either by changing the default OpenStack or Ansible dict, which would propagate to all repositories of that type or updating only the repositories `workflows` dict directly. Use the name of the jinja template. See below.

!!! info "ansible/inventory/group_vars/all/source-repositories"

    If you wish to update all repositories:

    ```yaml
    openstack_workflows:
      default_branch_only:
        - deploy
        - upstream-sync
      elsewhere:
        - tox
        - tag-and-release
    ```

    If you want the new additional workflow to only be included in specific repository:

    ```yaml
    source_repositories:
      kolla:
        workflows:
          additional_workflows:
            - deploy
    ```

#### Remove or omit workflows

To remove a workflow from being deployed or updated across all repositories simply remove it from either `openstack_workflows` or `ansible_workflows` dict.
If you would like to remove a workflow from a specific repository either because it is not necessary or you would prefer to manage that workflow within the repository itself then you can use `ignore_workflows` dict within the target repository.

Note however, this will not create a `pull request` to remove it from the repositories if it has already been deployed.

!!! info "ansible/inventory/group_vars/all/source-repositories"

    If you wish to remove a workflow from being deployed or updated for all repositories:

    ```yaml
    openstack_workflows:
      default_branch_only:
        - upstream-sync
      elsewhere:
        - tag-and-release
    ```

    If you wish to remove a workflow from being deployed or updated to a specific repository:

    ```yaml
    source_repositories:
      kolla:
        workflows:
          ignored_workflows:
            elsewhere:
              - tox
    ```

#### Managing CODEOWNERS

The playbook is also capable of managing the `CODEOWNERS` file for any repository listed within `source_repositories`.
The `CODEOWNERS` file for a given repository can be found under `roles/source-repo-sync/files/codeowners` and shares the same name as the target repository.
See [github documentation on CODEOWNERS](https://docs.github.com/en/repositories/managing-your-repositorys-settings-and-features/customizing-your-repository/about-code-owners)

!!! warning
    The playbook assumes that all repositories will have `CODEOWNERS` file if this is not the case you must declare `copy_codeowners` as `false` within `source_repositories` for all repositories that this is the case.

### Additional Notes

* All `commits` and `pull requests` are authored by the [stackhpc-ci](https://github.com/stackhpc-ci) bot. The bots personal access token has been added to the secrets of this repository.

* If a `branch` or `pull request` originating from the `source repositories playbook` is not closed or deleted, prior to running further additonal changes then the bot will automatically delete the `branch` and `pull request` making room for the new changes.

* The `source repositories playbook` will **NOT** delete unmanaged files or branches. For example when we drop support for `stackhpc/victoria` the playbook will **NOT** delete the workflows from that branch.

* Due to the extensive use of the Github API the playbook will pause after every `pull request` for 10 seconds.

