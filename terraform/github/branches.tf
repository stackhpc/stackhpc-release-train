resource "github_branch_protection" "ansible_branch_protection" {
  for_each      = toset(var.repositories["Ansible"])
  repository_id = data.github_repository.repositories[each.key].node_id

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

  required_status_checks {
    contexts = lookup(var.required_status_checks, each.key, { "default" : [] }).default
    strict   = false
  }

  lifecycle {
    prevent_destroy = true
  }
}

resource "github_branch_protection" "batch_branch_protection" {
  for_each      = toset(var.repositories["Batch"])
  repository_id = data.github_repository.repositories[each.key].node_id

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

  required_status_checks {
    contexts = lookup(var.required_status_checks, each.key, { "default" : [] }).default
    strict   = false
  }

  lifecycle {
    prevent_destroy = true
  }
}

resource "github_branch_protection" "kayobe_branch_protection_py_3-6" {
  for_each      = toset(var.repositories["Kayobe"])
  repository_id = data.github_repository.repositories[each.key].node_id

  # NOTE(Alex-Welsh): The pattern here is not ideal but it is difficult to
  # achieve more precision with the matching tools that GitHub provides.
  # https://stackoverflow.com/questions/53135414/how-to-apply-one-github-branch-rule-to-multiple-branches
  # Remember to update import_resources.py!
  pattern                         = "stackhpc/[vwxy]*"
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

  required_status_checks {
    contexts = lookup(lookup(var.required_status_checks, each.key, {}), "stackhpc/[vwxy]*", lookup(var.required_status_checks, each.key, {
      "default" : [
        "tox / Tox pep8 with Python 3.8",
        "tox / Tox py3 with Python 3.8"
      ]
    }).default)
    strict = false
  }

  lifecycle {
    prevent_destroy = false
  }
}

resource "github_branch_protection" "kayobe_branch_protection_zed" {
  for_each      = toset(var.repositories["Kayobe"])
  repository_id = data.github_repository.repositories[each.key].node_id

  pattern                         = "stackhpc/zed"
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

  required_status_checks {
    contexts = lookup(lookup(var.required_status_checks, each.key, {}), "stackhpc/zed", lookup(var.required_status_checks, each.key, {
      "default" : [
        "tox / Tox pep8 with Python 3.10",
        "tox / Tox py3 with Python 3.10",
        "tox / Tox py3 with Python 3.8"
      ]
    }).default)
    strict = false
  }

  lifecycle {
    prevent_destroy = true
  }
}

resource "github_branch_protection" "kayobe_branch_protection_antelope" {
  for_each      = toset(var.repositories["Kayobe"])
  repository_id = data.github_repository.repositories[each.key].node_id

  pattern                         = "stackhpc/2023.1"
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

  required_status_checks {
    contexts = lookup(lookup(var.required_status_checks, each.key, {}), "stackhpc/2023.1", lookup(var.required_status_checks, each.key, {
      "default" : [
        "tox / Tox pep8 with Python 3.10",
        "tox / Tox py3 with Python 3.10",
        "tox / Tox py3 with Python 3.8"
      ]
    }).default)
    strict = false
  }

  lifecycle {
    prevent_destroy = true
  }
}

resource "github_branch_protection" "kayobe_branch_protection_caracal" {
  for_each      = toset(var.repositories["Kayobe"])
  repository_id = data.github_repository.repositories[each.key].node_id

  pattern                         = "stackhpc/2024.1"
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

  required_status_checks {
    contexts = lookup(lookup(var.required_status_checks, each.key, {}), "stackhpc/2024.1", lookup(var.required_status_checks, each.key, {
      "default" : [
        "tox / Tox pep8 with Python 3.10",
        "tox / Tox py3 with Python 3.10"
      ]
    }).default)
    strict = false
  }

  lifecycle {
    prevent_destroy = true
  }
}

resource "github_branch_protection" "kayobe_branch_protection_epoxy" {
  for_each      = toset(var.repositories["Kayobe"])
  repository_id = data.github_repository.repositories[each.key].node_id

  pattern                         = "stackhpc/2025.1"
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

  required_status_checks {
    contexts = lookup(lookup(var.required_status_checks, each.key, {}), "stackhpc/2025.1", lookup(var.required_status_checks, each.key, {
      "default" : [
        "tox / Tox pep8 with Python 3.12",
        "tox / Tox py3 with Python 3.12",
        "tox / Tox py3 with Python 3.10"
      ]
    }).default)
    strict = false
  }

  lifecycle {
    prevent_destroy = true
  }
}


resource "github_branch_protection" "kayobe_branch_protection_master" {
  for_each      = toset(var.repositories["Kayobe"])
  repository_id = data.github_repository.repositories[each.key].node_id

  pattern                         = "stackhpc/master"
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

  required_status_checks {
    contexts = lookup(lookup(var.required_status_checks, each.key, {}), "stackhpc/master", lookup(var.required_status_checks, each.key, {
      "default" : [
        "tox / Tox pep8 with Python 3.12",
        "tox / Tox py3 with Python 3.12"
      ]
    }).default)
    strict = false
  }

  lifecycle {
    prevent_destroy = true
  }
}

resource "github_branch_protection" "openstack_branch_protection_py_3-6" {
  for_each      = toset(var.repositories["OpenStack"])
  repository_id = data.github_repository.repositories[each.key].node_id

  # NOTE(Alex-Welsh): The pattern here is not ideal but it is difficult to
  # achieve more precision with the matching tools that GitHub provides.
  # https://stackoverflow.com/questions/53135414/how-to-apply-one-github-branch-rule-to-multiple-branches
  # Remember to update import_resources.py!
  pattern                         = "stackhpc/[vwxy]*"
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
    contexts = lookup(lookup(var.required_status_checks, each.key, {}), "stackhpc/[vwxy]*", lookup(var.required_status_checks, each.key, {
      "default" : [
        "tox / Tox pep8 with Python 3.8",
        "tox / Tox py3 with Python 3.8"
      ]
    }).default)
    strict = false
  }
  lifecycle {
    prevent_destroy = true
  }
}

resource "github_branch_protection" "openstack_branch_protection_zed" {
  for_each      = toset(var.repositories["OpenStack"])
  repository_id = data.github_repository.repositories[each.key].node_id

  pattern                         = "stackhpc/zed"
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
    contexts = lookup(lookup(var.required_status_checks, each.key, {}), "stackhpc/zed", lookup(var.required_status_checks, each.key, {
      "default" : [
        "tox / Tox pep8 with Python 3.10",
        "tox / Tox py3 with Python 3.10",
        "tox / Tox py3 with Python 3.8"
      ]
    }).default)
    strict = false
  }

  lifecycle {
    prevent_destroy = false
  }
}

resource "github_branch_protection" "openstack_branch_protection_antelope" {
  for_each      = toset(var.repositories["OpenStack"])
  repository_id = data.github_repository.repositories[each.key].node_id

  pattern                         = "stackhpc/2023.1"
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
    contexts = lookup(lookup(var.required_status_checks, each.key, {}), "stackhpc/2023.1", lookup(var.required_status_checks, each.key, {
      "default" : [
        "tox / Tox pep8 with Python 3.10",
        "tox / Tox py3 with Python 3.10",
        "tox / Tox py3 with Python 3.8"
      ]
    }).default)
    strict = false
  }

  lifecycle {
    prevent_destroy = false
  }
}

resource "github_branch_protection" "openstack_branch_protection_caracal" {
  for_each      = toset(var.repositories["OpenStack"])
  repository_id = data.github_repository.repositories[each.key].node_id

  pattern                         = "stackhpc/2024.1"
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
    contexts = lookup(lookup(var.required_status_checks, each.key, {}), "stackhpc/2024.1", lookup(var.required_status_checks, each.key, {
      "default" : [
        "tox / Tox pep8 with Python 3.10",
        "tox / Tox py3 with Python 3.10"
      ]
    }).default)
    strict = false
  }

  lifecycle {
    prevent_destroy = false
  }
}

resource "github_branch_protection" "openstack_branch_protection_epoxy" {
  for_each      = toset(var.repositories["OpenStack"])
  repository_id = data.github_repository.repositories[each.key].node_id

  pattern                         = "stackhpc/2025.1"
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
    contexts = lookup(lookup(var.required_status_checks, each.key, {}), "stackhpc/2025.1", lookup(var.required_status_checks, each.key, {
      "default" : [
        "tox / Tox pep8 with Python 3.12",
        "tox / Tox py3 with Python 3.12",
        "tox / Tox py3 with Python 3.10"
      ]
    }).default)
    strict = false
  }

  lifecycle {
    prevent_destroy = false
  }
}

resource "github_branch_protection" "openstack_branch_protection_master" {
  for_each      = toset(var.repositories["OpenStack"])
  repository_id = data.github_repository.repositories[each.key].node_id

  pattern                         = "stackhpc/master"
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
    contexts = lookup(lookup(var.required_status_checks, each.key, {}), "stackhpc/master", lookup(var.required_status_checks, each.key, {
      "default" : [
        "tox / Tox pep8 with Python 3.12",
        "tox / Tox py3 with Python 3.12",
        "tox / Tox py3 with Python 3.10"
      ]
    }).default)
    strict = false
  }

  lifecycle {
    prevent_destroy = false
  }
}

resource "github_branch_protection" "platform_branch_protection" {
  for_each      = toset(var.repositories["Platform"])
  repository_id = data.github_repository.repositories[each.key].node_id

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

  required_status_checks {
    contexts = lookup(var.required_status_checks, each.key, { "default" : [] }).default
    strict   = false
  }

  lifecycle {
    prevent_destroy = true
  }
}

resource "github_branch_protection" "releasetrain_branch_protection" {
  for_each      = toset(var.repositories["ReleaseTrain"])
  repository_id = data.github_repository.repositories[each.key].node_id

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

  required_status_checks {
    contexts = lookup(var.required_status_checks, each.key, { "default" : [] }).default
    strict   = false
  }

  lifecycle {
    prevent_destroy = true
  }
}

resource "github_branch_protection" "smslab_branch_protection" {
  for_each      = toset(var.repositories["SMSLab"])
  repository_id = data.github_repository.repositories[each.key].node_id

  pattern                         = "smslab/[y,z,2]*"
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

  required_status_checks {
    contexts = lookup(var.required_status_checks, each.key, { "default" : [] }).default
    strict   = false
  }

  lifecycle {
    prevent_destroy = true
  }
}

