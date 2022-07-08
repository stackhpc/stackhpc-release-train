#variable "GITHUB_TOKEN" {
#  type        = string
#  description = "GitHub token required for authentication"
#  sensitive = true
#}

variable "github_app_pem_file" {
  type        = string
  description = "GitHub application pem file required for authentication"
  sensitive   = true
}

variable "owner" {
  default = "stackhpc"
}

variable "repositories" {
  default = {
    "Ansible"      = [],
    "Azimuth"      = [],
    "Batch"        = [],
    "Kayobe"       = [],
    "OpenStack"    = [],
    "ReleaseTrain" = [],
    "SMSLab"       = [],
  }
}

variable "teams" {
  default = {
    "Ansible" = {
      description = "Team responsible for Ansible development"
      privacy     = "closed"
      users = {
        maintainers = [],
        members = [
          "stackhpc-ci"
        ],
      }
    },
    "Azimuth" = {
      description = "Team responsible for Azimuth development"
      privacy     = "closed"
      users = {
        maintainers = [],
        members = [
          "stackhpc-ci"
        ],
      }
    },
    "Batch" = {
      description = "Team responsible for Batch development"
      privacy     = "closed"
      users = {
        maintainers = [],
        members = [
          "stackhpc-ci"
        ],
      }
    },
    "Developers" = {
      description = "All employees are a member of this team"
      privacy     = "closed"
      users = {
        maintainers = [],
        members = [
          "stackhpc-ci"
        ],
      }
    },
    "Kayobe" = {
      description = "Team responsible for Kayobe development"
      privacy     = "closed"
      users = {
        maintainers = [],
        members = [
          "stackhpc-ci"
        ],
      }
    },
    "OpenStack" = {
      description = "Team responsible for OpenStack development"
      privacy     = "closed"
      users = {
        maintainers = [],
        members = [
          "stackhpc-ci"
        ],
      }
    },
    "ReleaseTrain" = {
      description = "Team responsible for Release Train development"
      privacy     = "closed"
      users = {
        maintainers = [],
        members = [
          "stackhpc-ci"
        ],
      }
    },
    "SMSLab" = {
      description = "Team responsible for SMS Lab development"
      privacy     = "closed"
      users = {
        maintainers = [],
        members = [
          "stackhpc-ci"
        ],
      }
    },
  }
}