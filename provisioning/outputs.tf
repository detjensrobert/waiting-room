output "pod_name" {
  value = kubernetes_manifest.runner_pod.object.metadata.name
}
