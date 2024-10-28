output "instance_ip" {
  description = "The external IP address of the instance"
  value       = google_compute_address.static_ip.address
}

output "instance_name" {
  description = "The name of the instance"
  value       = google_compute_instance.newpush_lab.name
}

output "instance_self_link" {
  description = "The self_link of the instance"
  value       = google_compute_instance.newpush_lab.self_link
}