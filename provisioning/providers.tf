terraform {
  required_providers {
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.23.0"
    }
    gitlab = {
      source  = "gitlabhq/gitlab"
      version = "~> 16.10.0"
    }
  }
}

provider "gitlab" {
  base_url = "https://${var.gitlab_url}/api/v4"
  token = var.gitlab_user_token
}

provider "kubernetes" {
}
