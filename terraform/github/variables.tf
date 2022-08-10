variable "GITHUB_TOKEN" {
  type        = string
  default     = null
  nullable    = true
  description = "GitHub token required for authentication"
  sensitive   = true
}

variable "GITHUB_APP_PEM_FILE" {
  type        = string
  default     = null
  nullable    = true
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
        members     = [],
      }
    },
    "Azimuth" = {
      description = "Team responsible for Azimuth development"
      privacy     = "closed"
      users = {
        maintainers = [],
        members     = [],
      }
    },
    "Batch" = {
      description = "Team responsible for Batch development"
      privacy     = "closed"
      users = {
        maintainers = [],
        members     = [],
      }
    },
    "Developers" = {
      description = "All employees are a member of this team"
      privacy     = "closed"
      users = {
        maintainers = [],
        members     = [],
      }
    },
    "Kayobe" = {
      description = "Team responsible for Kayobe development"
      privacy     = "closed"
      users = {
        maintainers = [],
        members     = [],
      }
    },
    "OpenStack" = {
      description = "Team responsible for OpenStack development"
      privacy     = "closed"
      users = {
        maintainers = [],
        members     = [],
      }
    },
    "ReleaseTrain" = {
      description = "Team responsible for Release Train development"
      privacy     = "closed"
      users = {
        maintainers = [],
        members     = [],
      }
    },
    "SMSLab" = {
      description = "Team responsible for SMS Lab development"
      privacy     = "closed"
      users = {
        maintainers = [],
        members     = [],
      }
    },
  }
}

variable "labels" {
  default = []
}

# Map from repository name to a list of required status checks.
# This can be used to override the default required status checks.
# TODO: refactor this into the repositories list.
variable "required_status_checks" {
  default = {}
}
