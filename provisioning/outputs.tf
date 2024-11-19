output "pod_name" {
  # value = kubectl_manifest.runner_vm_pod.name
  value = kubernetes_manifest.runner_vm_pod.object.metadata.name
}
