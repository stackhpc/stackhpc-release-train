resource "github_repository" "repositories" {
  for_each               = toset(flatten(values(var.repositories)))
  name                   = each.value
  delete_branch_on_merge = true
  allow_merge_commit     = true
  allow_squash_merge     = true
  allow_rebase_merge     = true
  allow_auto_merge       = true
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

resource "github_issue_label" "arm64_label" {
  for_each    = toset(flatten(values(var.repositories)))
  repository  = each.value
  name        = "arm64"
  color       = "0E8A16"
  description = "Work related to ARM architecture support"
}

resource "github_issue_label" "automated_label" {
  for_each    = toset(flatten(values(var.repositories)))
  repository  = each.value
  name        = "automated"
  color       = "C4F2A5"
  description = "Automated action performed by GitHub Actions"
}

resource "github_issue_label" "workflows_label" {
  for_each    = toset(flatten(values(var.repositories)))
  repository  = each.value
  name        = "workflows"
  color       = "638475"
  description = "Workflow files have been modified"
}

resource "github_issue_label" "community_files_label" {
  for_each    = toset(flatten(values(var.repositories)))
  repository  = each.value
  name        = "community-files"
  color       = "3F84E5"
  description = "Community files have been modified"
}

resource "github_issue_label" "magnum_label" {
  for_each    = toset(flatten(values(var.repositories)))
  repository  = each.value
  name        = "magnum"
  color       = "6B0560"
  description = "All things OpenStack Magnum related"
}

resource "github_issue_label" "monitoring_label" {
  for_each    = toset(flatten(values(var.repositories)))
  repository  = each.value
  name        = "monitoring"
  color       = "FBCA04"
  description = "All things related to observability & telemetry"
}

data "github_repository" "repositories" {
  for_each  = toset(flatten(values(var.repositories)))
  full_name = format("%s/%s", var.owner, each.value)
}
