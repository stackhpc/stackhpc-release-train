terraform {
  required_providers {
    github = {
      source  = "integrations/github"
      version = "4.28.0"
    }
  }
  cloud {
    organization = "stackhpc"

    workspaces {
      name = "github-testing"
    }
  }
}

provider "github" {
  owner = var.owner
  app_auth {
    id              = 218102
    installation_id = 27194723
    pem_file        = var.GITHUB_APP_PEM_FILE
  }
}

# Use this provider block if you would prefer to use a GitHub token
# provider "github" {
#   owner = var.owner
#   token = var.GITHUB_TOKEN
# }