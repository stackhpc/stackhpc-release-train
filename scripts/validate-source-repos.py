import json
import yaml


def read_repos_data():
    terraform_repositories = {}
    ansible_repositories = {}

    with open('terraform/github/terraform.tfvars.json', 'r') as file:
        data = json.loads(file.read())
        terraform_repositories = data['repositories']

    with open('ansible/inventory/group_vars/all/source-repositories',
              'r') as file:
        data = yaml.load(file.read(), Loader=yaml.SafeLoader)
        ansible_repositories = data['source_repositories']

    return terraform_repositories, ansible_repositories


def get_repos_diff(tf_repos, ans_repos):
    ans_repos_list = list(ans_repos.keys())

    tf_repos_list = []
    for team in tf_repos:
        tf_repos_list += tf_repos[team]

    diff = list(set(tf_repos_list).symmetric_difference(ans_repos_list))

    return diff


def _extract_group_from_community_files(files):
    for file in files:
        if 'codeowners' in file:
            content = file['codeowners']['content']
            return content.strip('{ }').replace('_', '').split('.')[-1]


def _sort_ans_repos_by_group(ans_repos):
    ans_repos_by_group = {}
    for repo in ans_repos:
        files = ans_repos[repo]['community_files']
        group = _extract_group_from_community_files(files)
        if group in ans_repos_by_group:
            ans_repos_by_group[group].append(repo)
        else:
            ans_repos_by_group[group] = [repo]
    return ans_repos_by_group


def get_mismatched_repos(tf_repos, ans_repos, repos_missing):
    ans_repos_new = _sort_ans_repos_by_group(ans_repos)
    tf_repos_new = {k.lower(): v for k, v in tf_repos.items()}

    mismatched_repos = []
    for group in tf_repos_new:
        if len(tf_repos_new[group]) == 0 or group not in ans_repos_new:
            continue
        else:
            diff = list(set(tf_repos_new[group]).symmetric_difference(
                set(ans_repos_new[group])))
            mismatched_repos.extend(diff)
    return list(set(mismatched_repos).difference(set(repos_missing)))


def main():
    terraform_repos, ansible_repos = read_repos_data()

    repos_missing = get_repos_diff(terraform_repos, ansible_repos)

    print('The following repos are only present in one of the Ansible '
          f'source-repositories and the Terraform tfvars: {repos_missing}')

    mismatched_repos = get_mismatched_repos(terraform_repos, ansible_repos,
                                            repos_missing)

    print('The following repos are assigned to different codeowner groups in '
         'the Ansible source-repositories and the Terraform tfvars: '
         f'{mismatched_repos}')

    if len(repos_missing) > 0 or len(mismatched_repos) > 0:
        return 1
    else:
        return 0


main()
