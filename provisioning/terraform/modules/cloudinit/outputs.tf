output "rendered_config" {
  description = "Rendered cloud-init configuration"
  value       = data.cloudinit_config.config.rendered
  sensitive   = true
}
