variable "gitlab_url" {
  type = string
  description = "gitlab endpoint"
  sensitive = true
}

variable "gitlab_user_token" {
  type = string
  description = "gitlab api token for project user"
  sensitive = true
}

variable "session_id" {
  description = "user session id from waiting room"
  type = string
}

variable "template_project" {
  description = "path with namespace of project to fork"
}
