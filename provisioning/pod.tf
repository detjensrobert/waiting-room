# deploy runner pod and creds secret template
resource "kubernetes_secret" "runner_creds" {
  metadata {
    name = "runner-${ var.session_id }-creds"
    namespace = "runners"
  }
  data = {
    "creds.env" = <<-CREDS
      CI_SERVER_URL="https://${var.gitlab_url}"
      RUNNER_NAME="my-runner"
      REGISTRATION_TOKEN="${gitlab_user_runner.chal_runner.token}"
    CREDS
  }
}

resource "kubernetes_manifest" "runner_vm_pod" {
  manifest = yamldecode(
    templatefile("runner.pod.yaml.tftpl",
    { id = var.session_id, secret = kubernetes_secret.runner_creds.metadata[0].name })
  )

  computed_fields = ["spec.volumes"]

  wait {
    fields = {
      # Check the phase of a pod
      "status.phase" = "Running"
    }
  }

  timeouts {
    create = "15m"
  }
}
