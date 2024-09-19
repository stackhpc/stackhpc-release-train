# Secrets

Various [GitHub Actions secrets](https://github.com/stackhpc/stackhpc-release-train/settings/secrets/actions) are used within StackHPC Release Train for integrating with external services.
All secrets are scoped to the StackHPC Release Train repository unless stated otherwise.

| Secret                           | Type                      | Owner                   | Description                                                                                         |
| -------------------------------- | ------------------------- | ----------------------- | --------------------------------------------------------------------------------------------------- |
| `ANSIBLE_VAULT_PASSWORD`         | Ansible vault password    | N/A                     | Ansible Vault password for StackHPC Release Train secrets.
| `GALAXY_API_KEY`                 | Ansible Galaxy API token  | stackhpc-ci GitHub user | Organisation secret used for importing Ansible content into Ansible Galaxy.                         |
| `repository_configuration_token` | GitHub PAT token          | stackhpc-ci GitHub user | Used in [source code CI](source-code-ci.md) to create GitHub pull requests.                         |
|                                  |                           |                         | Used in [GitHub organisation management](github-organisation-management.md) to add comments to PRs. |
| `SLACK_WEBHOOK_URL`              | Slack webhook URL         | Infra team leads        | Used to send Slack notifications on GitHub Actions workflow failures.                               |
| `TF_API_TOKEN`                   | Terraform Cloud API token | Jack                    | Used in GitHub organisation management to authenticate with Terraform cloud.                        |
| `TF_VAR_GITHUB_APP_PEM_FILE`     | GitHub app PEM file       | GitHub org admins       | Used in GitHub organisation management to authorise Terraform to manage GitHub repositories.        |
