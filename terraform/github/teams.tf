resource "github_team" "organisation_teams" {
  for_each    = var.teams
  name        = each.key
  description = each.value.description
  privacy     = each.value.privacy
  lifecycle {
    prevent_destroy = true
  }
}

resource "github_team_repository" "ansible_repositories" {
  for_each   = toset(var.repositories["Ansible"])
  team_id    = resource.github_team.organisation_teams["Ansible"].id
  repository = each.value
  permission = "push"
  lifecycle {
    prevent_destroy = true
  }
}

resource "github_team_repository" "azimuth_repositories" {
  for_each   = toset(var.repositories["Azimuth"])
  team_id    = resource.github_team.organisation_teams["Azimuth"].id
  repository = each.value
  permission = "push"
  lifecycle {
    prevent_destroy = true
  }
}

resource "github_team_repository" "batch_repositories" {
  for_each   = toset(var.repositories["Batch"])
  team_id    = resource.github_team.organisation_teams["Batch"].id
  repository = each.value
  permission = "push"
  lifecycle {
    prevent_destroy = true
  }
}

resource "github_team_repository" "developers_repositories" {
  for_each   = toset(flatten(values(var.repositories)))
  team_id    = resource.github_team.organisation_teams["Developers"].id
  repository = each.value
  permission = "push"
  lifecycle {
    prevent_destroy = true
  }
}

resource "github_team_repository" "kayobe_repositories" {
  for_each   = toset(var.repositories["Kayobe"])
  team_id    = resource.github_team.organisation_teams["Kayobe"].id
  repository = each.value
  permission = "push"
  lifecycle {
    prevent_destroy = true
  }
}

resource "github_team_repository" "openstack_repositories" {
  for_each   = toset(var.repositories["OpenStack"])
  team_id    = resource.github_team.organisation_teams["OpenStack"].id
  repository = each.value
  permission = "push"
  lifecycle {
    prevent_destroy = true
  }
}

resource "github_team_repository" "releasetrain_repositories" {
  for_each   = toset(var.repositories["ReleaseTrain"])
  team_id    = resource.github_team.organisation_teams["ReleaseTrain"].id
  repository = each.value
  permission = "push"
  lifecycle {
    prevent_destroy = true
  }
}

resource "github_team_repository" "smslab_repositories" {
  for_each   = toset(var.repositories["SMSLab"])
  team_id    = resource.github_team.organisation_teams["SMSLab"].id
  repository = each.value
  permission = "push"
  lifecycle {
    prevent_destroy = true
  }
}

resource "github_team_membership" "team_membership" {
  for_each = { for element in flatten([
    for team in resource.github_team.organisation_teams : [
      for role in keys(var.teams[team.name].users) : [
        for user in var.teams[team.name].users[role] : {
          name     = "${team.name}:${user}",
          team_id  = team.id,
          username = user,
          role     = trim(role, "s")
        }
      ]
    ]
  ]) : element.name => element }
  team_id  = each.value.team_id
  username = each.value.username
  role     = each.value.role
  lifecycle {
    prevent_destroy = true
  }
}
