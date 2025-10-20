#
# Templates out and applies the runner pod after creating all the other
# necessary resources provisioned as part of this Tofu code.
#


# Example of how to share secrets or other information from the other Tofu
# resources with the pod as environment variables. Make sure to update the pod
# template if this is renamed or other secrets/configmaps are added!
resource "kubernetes_secret" "runner_creds" {
  metadata {
    name      = "runner-${var.session_id}-creds"
    namespace = "runners"
  }
  data = {
    "creds.env" = <<-CREDS
      THIS_IS_AN=example of passing some secret to the pod
      FOO_ID=${random_uuid.dummy_value.result}
    CREDS
  }
}

resource "kubernetes_manifest" "runner_pod" {
  manifest = yamldecode(
    templatefile("runner.pod.yaml.tftpl", {
      id     = var.session_id,
      secret = kubernetes_secret.runner_creds.metadata[0].name
    })
  )

  computed_fields = ["spec.volumes"]

  # Wait during the Tofu apply for pod to become ready
  wait {
    fields = {
      "status.phase" = "Running"
    }
  }

  # Adjust this timeout to whatever is reasonable for this application
  timeouts {
    create = "15m"
  }
}
