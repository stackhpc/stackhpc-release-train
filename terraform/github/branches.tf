resource "github_branch_protection" "ansible_branch_protection" {
  for_each      = toset(var.repositories["Ansible"])
  repository_id = each.key

  pattern                         = data.github_repository.repositories[each.key].default_branch
  require_conversation_resolution = true
  allows_deletions                = false
  allows_force_pushes             = false

  required_pull_request_reviews {
    dismiss_stale_reviews           = true
    require_code_owner_reviews      = true
    required_approving_review_count = 1
  }

  # Only permit members of the `Developers` team to push to the protected branch. Members 
  # would still need to get the required approval from reviewers and pass any checks before 
  # being able to merge. Also this should prevent outsiders from pushing to the protected branch, 
  # however, whilst they can open a pull request they shoud not be able to merge that would be 
  # upto the reviewers or codeowners. 
  push_restrictions = [
    resource.github_team.organisation_teams["Developers"].node_id
  ]

  lifecycle {
    prevent_destroy = true
  }
}

resource "github_branch_protection" "azimuth_branch_protection" {
  for_each      = toset(var.repositories["Azimuth"])
  repository_id = each.key

  pattern                         = data.github_repository.repositories[each.key].default_branch
  require_conversation_resolution = true
  allows_deletions                = false
  allows_force_pushes             = false

  required_pull_request_reviews {
    dismiss_stale_reviews           = true
    require_code_owner_reviews      = true
    required_approving_review_count = 1
  }

  push_restrictions = [
    resource.github_team.organisation_teams["Developers"].node_id
  ]

  lifecycle {
    prevent_destroy = true
  }
}

resource "github_branch_protection" "batch_branch_protection" {
  for_each      = toset(var.repositories["Batch"])
  repository_id = each.key

  pattern                         = data.github_repository.repositories[each.key].default_branch
  require_conversation_resolution = true
  allows_deletions                = false
  allows_force_pushes             = false

  required_pull_request_reviews {
    dismiss_stale_reviews           = true
    require_code_owner_reviews      = true
    required_approving_review_count = 1
  }

  push_restrictions = [
    resource.github_team.organisation_teams["Developers"].node_id
  ]

  lifecycle {
    prevent_destroy = true
  }
}

resource "github_branch_protection" "kayobe_branch_protection" {
  for_each      = toset(var.repositories["Kayobe"])
  repository_id = each.key

  pattern                         = "stackhpc/**"
  require_conversation_resolution = true
  allows_deletions                = false
  allows_force_pushes             = false

  required_pull_request_reviews {
    dismiss_stale_reviews           = true
    require_code_owner_reviews      = true
    required_approving_review_count = 1
  }

  push_restrictions = [
    resource.github_team.organisation_teams["Developers"].node_id
  ]

  lifecycle {
    prevent_destroy = true
  }
}

resource "github_branch_protection" "openstack_branch_protection" {
  for_each      = toset(var.repositories["OpenStack"])
  repository_id = each.key

  pattern                         = "stackhpc/**"
  require_conversation_resolution = true
  allows_deletions                = false
  allows_force_pushes             = false

  push_restrictions = [
    resource.github_team.organisation_teams["Developers"].node_id
  ]

  required_pull_request_reviews {
    dismiss_stale_reviews           = true
    require_code_owner_reviews      = true
    required_approving_review_count = 1
  }

  required_status_checks {
    contexts = [
      "tox / Tox pep8 with Python 3.8",
      "tox / Tox py36 with Python 3.6",
      "tox / Tox py38 with Python 3.8",
    ]
    strict = true
  }

  lifecycle {
    prevent_destroy = true
  }
}

resource "github_branch_protection" "release_train_branch_protection" {
  for_each      = toset(var.repositories["ReleaseTrain"])
  repository_id = each.key

  pattern                         = data.github_repository.repositories[each.key].default_branch
  require_conversation_resolution = true
  allows_deletions                = false
  allows_force_pushes             = false

  required_pull_request_reviews {
    dismiss_stale_reviews           = true
    require_code_owner_reviews      = true
    required_approving_review_count = 1
  }

  push_restrictions = [
    resource.github_team.organisation_teams["Developers"].node_id
  ]

  lifecycle {
    prevent_destroy = true
  }
}

resource "github_branch_protection" "sms_lab_branch_protection" {
  for_each      = toset(var.repositories["SMSLab"])
  repository_id = each.key

  pattern                         = data.github_repository.repositories[each.key].default_branch
  require_conversation_resolution = true
  allows_deletions                = false
  allows_force_pushes             = false

  required_pull_request_reviews {
    dismiss_stale_reviews           = true
    require_code_owner_reviews      = true
    required_approving_review_count = 1
  }

  push_restrictions = [
    resource.github_team.organisation_teams["Developers"].node_id
  ]

  lifecycle {
    prevent_destroy = true
  }
}