terraform {
  required_providers {
    github = {
      source  = "integrations/github"
      version = "4.26.1"
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
    pem_file        = var.github_app_pem_file
  }
}
