terraform {
  required_providers {
    github = {
      source  = "integrations/github"
      version = "6.11.1"
    }
  }

  backend "s3" {
    bucket       = "github-terraform-backend"
    key          = "github/terraform.tfstate"
    region       = "auto" # Cloudflare R2 uses "auto" for the region
    use_lockfile = true

    endpoints = {
      s3 = "https://99e8d2e95b14ef888ce364a5ab310629.r2.cloudflarestorage.com"
    }

    # Bypasses strict AWS checks so the S3-compatible API works
    skip_credentials_validation = true
    skip_region_validation      = true
    skip_requesting_account_id  = true
    skip_metadata_api_check     = true
    skip_s3_checksum            = true
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
