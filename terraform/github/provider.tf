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
      name = "github-stackhpc"
    }
  }
}

provider "github" {
  token = var.GITHUB_TOKEN
  owner = var.owner
}