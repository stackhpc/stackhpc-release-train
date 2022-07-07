resource "github_repository" "repositories" {
  for_each               = toset(flatten(values(var.repositories)))
  name                   = each.value
  delete_branch_on_merge = true
  lifecycle {
    ignore_changes = [
      description,
      homepage_url,
      private,
      visibility,
      has_issues,
      has_projects,
      has_wiki,
      is_template,
      allow_merge_commit,
      allow_squash_merge,
      allow_rebase_merge,
      has_downloads,
      auto_init,
      gitignore_template,
      license_template,
      default_branch,
      archived,
      archive_on_destroy,
      pages,
      topics,
      template,
      vulnerability_alerts,
      ignore_vulnerability_alerts_during_read
    ]
    prevent_destroy = true
  }
}

resource "github_issue_label" "stackhpc_label" {
  for_each    = toset(flatten(values(var.repositories)))
  repository  = each.value
  name        = "stackhpc-ci"
  color       = "E6E2C0"
  description = "Automated action performed by stackhpc-ci"
  lifecycle {
    prevent_destroy = true
  }
}

resource "github_issue_label" "workflows_label" {
  for_each    = toset(flatten(values(var.repositories)))
  repository  = each.value
  name        = "workflows"
  color       = "638475"
  description = "Workflow files have been modified"
  lifecycle {
    prevent_destroy = true
  }
}

resource "github_issue_label" "community_files_label" {
  for_each    = toset(flatten(values(var.repositories)))
  repository  = each.value
  name        = "community-files"
  color       = "3F84E5"
  description = "Community files have been modified"
  lifecycle {
    prevent_destroy = true
  }
}

data "github_repository" "repositories" {
  for_each  = toset(flatten(values(var.repositories)))
  full_name = format("%s/%s", var.owner, each.value)
}