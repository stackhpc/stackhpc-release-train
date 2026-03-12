terraform {
  required_providers {
    github = {
      source  = "integrations/github"
      version = "6.11.1"
    }
  }
  cloud {
    organization = "stackhpc"

    workspaces {
      name = "github"
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
