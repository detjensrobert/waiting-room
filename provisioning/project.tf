# fork project

data "gitlab_project" "template" {
  path_with_namespace = var.template_project
}

resource "gitlab_project" "fork" {
  name                   = "infra-stuff-${var.session_id}"
  path                   = "infra-stuff-${var.session_id}"
  forked_from_project_id = data.gitlab_project.template.id
  namespace_id           = data.gitlab_project.template.namespace_id
}



# upload ci file

# fetch from fork
data "http" "template_flag" {
  url = "https://${var.gitlab_url}/api/v4/projects/${data.gitlab_project.template.id}/secure_files/573/download"
  request_headers = {
    "PRIVATE-TOKEN" = var.gitlab_user_token
  }
}
# and upload to provider
resource "null_resource" "upload_flag" {
  provisioner "local-exec" {
    command = <<-CMD
      echo "${sensitive(data.http.template_flag.response_body)}" | \
      curl --request POST \
           "https://${var.gitlab_url}/api/v4/projects/${gitlab_project.fork.id}/secure_files" \
           --header "PRIVATE-TOKEN: ${var.gitlab_user_token}" \
           --form "name=flag" \
           --form "file=@-"
    CMD
  }

  triggers = { project = gitlab_project.fork.path_with_namespace }
}


# create project runner
resource "gitlab_user_runner" "chal_runner" {
  runner_type = "project_type"
  project_id = gitlab_project.fork.id

  untagged = true # run untagged jobs
  locked = true   # cant register for other projects
}

# schedule pipeline every 2 min
resource "gitlab_pipeline_schedule" "example" {
  project     = gitlab_project.fork.id
  description = "build frequently"
  ref         = "main"
  cron        = "*/2 * * * *" # every 2 mins
  active      = true
}
