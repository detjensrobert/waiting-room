# required! used by waiting-room script to exec player into created pod
output "pod_name" {
  value = kubernetes_manifest.runner_pod.object.metadata.name
}
