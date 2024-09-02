# Usage - source code continuous integration

Source code continuous integration (CI) is handled by Github Workflows.
There are currently three workflows in use, whose objective is to perform tedious tasks or to ensure that the code is correct and style guidelines are being followed.
A brief overview of these workflows was given in the [Overview Section](../index.md#automation-continuous-integration-ci) whereas this section will provide additional insight into how these workflows function and how you can modify these workflows.
Also discussed are the community files used by Github to improve developer experience within the respositories in addition to how we intend to synchronise all of the source code repositories with latests files.

## Github Workflows

This section is simply intended to document the behaviour of these workflows actual modification should be handled via the Synchronise Repositories Playbook which is documented below in [Synchronise Repositories Playbook Section](#synchronise-repositories-playbook).
The table below contains the different workflows with a description of each and the project type they would are used within.

| Workflow               | Description                                                                                 | Project Type         |
| :--------------------: | ------------------------------------------------------------------------------------------- | :------------------: |
| **Upstream Sync**      | Keep our downstream fork up-to-date with the upstream counterpart                           | OpenStack            |
| **Tag & Release**      | Generate an new tag and accompanying release whenever a commit is pushed to select branches | OpenStack            |
| **Tox**                | Perform linting and unit testing                                                            | OpenStack            |
| **Lint Collection**    | Perform linting and sanity checks on Ansible collections                                    | Ansible (Collection) |
| **Publish Role**       | Publish the Ansible Role on Ansible Galaxy                                                  | Ansible (Role)       |
| **Publish Collection** | Publish the Ansible Collection on Ansible Galaxy                                            | Ansible (Collection) |

!!! info "Reusable Workflow Location"

    The following workflows are setup as [reusable workflows](https://docs.github.com/en/actions/using-workflows/reusing-workflows) and can be found within the [StackHPC/.github](https://github.com/stackhpc/.github/tree/main/.github/workflows) repository. The advantage of this approach means that changes to a given workflow can be made in one place rather than each repository individualy.

### Tox

OpenStack use [Tox](https://wiki.openstack.org/wiki/Testing) to manage the unit tests and style checks for the various projects they maintain.
Therefore, when a `pull request` is opened the tox workflow will automatically perform a series of unit tests and linting in order ensure correctness and style guidelines are being met.
The python environment will depend on the branch pre-Zed, python 3.6 and python 3.8 will be tested. From Zed onward, python 3.8 and python 3.10 will be tested, though only python 3.10 will be required for Caracal.
This can be controlled within the strategy matrix of the workflow.
The Python versions should correspond to those used in the supported OS distributions for a particular release.
The source for the workflow can be found [here](https://github.com/stackhpc/.github/blob/main/.github/workflows/tox.yml).
It is managed centrally and imported into all downstream branches.


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

### Lint Collection

Ansible collections are linted using [Ansible lint](https://ansible.readthedocs.io/projects/lint/), and sanity checked using the `ansible-test sanity` command.
These checks run against pull requests to Ansible collection repositories and use a matrix to test multiple versions of Ansible.
The tested versions of Ansible should generally correspond to those used by supported versions of Kayobe and Kolla.

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
    * **ansible_workflows**: dictionary that contains either the type of Ansible `collection` or `role`
        * collection: list of workflows specific to Ansible collections
        * role: list of workflows specific to Ansible roles
    * **community_files**: dictionary of templates for various community files. 
      Each community file can have multiple templates are can be written as multiline strings.
    * **source_repositories**: dictionary of repositories targeted by the Ansible playbook
        * repository_name: points to repository, must match the name of the repository exactly.
            * repository_type: used to distinguish if the repository is OpenStack, Ansible or branchless, defaults to OpenStack if not provided
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
    community_files:
      codeowners:
        kayobe_codeowners: |
          * @stackhpc/kayobe
        ansible_codeowners: |
          * @stackhpc/ansible
    source_repositories:
      kolla:
        community_files:
          - codeowners:
              content: '{{ community_files.codeowners.kayobe_codeowners }}'
              dest: '.github/CODEOWNERS'
      barbican:
        ignored_releases:
          - victoria
          - xena
      stackhpc-inspector-plugins:
        repository_type: 'branchless'
        workflows: '{{ openstack_workflows.elsewhere }}'
      ansible-role-os-networks:
        repository_type: 'ansible'
        workflows: '{{ ansible_workflows.role }}'
      ansible-collection-cephadm:
        repository_type: 'ansible'
        workflows: '{{ ansible_workflows.collection }}'
    ```

In this subsection we shall explore how to make various modifications to the playbook. 
Please review the `Source Repositories Vars` for a description of the variables found within [source-repositories](https://github.com/stackhpc/stackhpc-release-train/blob/main/ansible/inventory/group_vars/all/source-repositories) vars file.

!!! note

    Modifications can be made either by clone the stackhpc-release-train repository locally or using the [Github Dev Editor](https://github.dev/github/dev) by pressing `.` key within the repository.

#### Add new repository

To add new repositories to be handled by this playbook you can edit [source-repositories](https://github.com/stackhpc/stackhpc-release-train/blob/main/ansible/inventory/group_vars/all/source-repositories).
Identify the `source_repositories` dictionary and insert your new repository.
For example the below code snippet will add neutron to the `source repo sync` all default workflows and community files.
Also all release series will be ignored except `yoga`.

```yaml
source_repositories:
  neutron:
    ignored_releases:
      - xena
      - wallaby
      - victoria
    community_files:
      - codeowners:
          content: "{{ community_files.codeowners.openstack }}"
          dest: ".github/CODEOWNERS"
```

!!! note

    Please refer to [Making modifications to the playbook](#making-modifications-to-the-playbook) for description of changes that can be made.

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

#### Managing Community Files

Github provides support for many [community files](https://docs.github.com/en/communities/setting-up-your-project-for-healthy-contributions/creating-a-default-community-health-file) that can be used throughout the release train repositories.
Currently we support `CODEOWNERS` files which will automatically assign a team or team member to a pull request that relates to code that they own.
All community files are stored in the `community_files` dictionary whereby the key is the name of file and then the value is a list of `templates` stored as multiline strings. 
To add a new community file or template simply expand the dictionary where appropriate and ensure that the relevant repositories are updated within the `source_repositories` dictionary.

```yaml
source_repositories:
  kolla:
    community_files:
      - codeowners:
          content: '{{ community_files.codeowners.kayobe_codeowners }}'
          dest: '.github/CODEOWNERS'
```

### Additional Notes

* All `commits` and `pull requests` are authored by the [stackhpc-ci](https://github.com/stackhpc-ci) bot. The bots personal access token has been added to the secrets of this repository.

* If a `branch` or `pull request` originating from the `source repositories playbook` is not closed or deleted, prior to running further additonal changes then the bot will automatically delete the `branch` and `pull request` making room for the new changes.

* The `source repositories playbook` will **NOT** delete unmanaged files or branches. For example when we drop support for `stackhpc/victoria` the playbook will **NOT** delete the workflows from that branch.

* Due to the extensive use of the Github API the playbook will pause after every `pull request` for 10 seconds.

