variable "project_id" {
  description = "GCP Project ID"
  type        = string
}

variable "region" {
  description = "GCP Region"
  type        = string
}

variable "zone" {
  description = "GCP Zone"
  type        = string
}

variable "instance_name" {
  description = "Name of the GCP instance"
  type        = string
}

variable "machine_type" {
  description = "GCP Machine Type"
  type        = string
  default     = "e2-medium"
}

variable "disk_image" {
  description = "Boot disk image"
  type        = string
  default     = "ubuntu-os-cloud/ubuntu-2204-lts"
}

variable "disk_size" {
  description = "Boot disk size in GB"
  type        = number
  default     = 80
}

variable "disk_type" {
  description = "Boot disk type"
  type        = string
  default     = "pd-standard"
}

variable "cloud_init_config" {
  description = "Cloud-init configuration"
  type        = string
  sensitive   = true
}
