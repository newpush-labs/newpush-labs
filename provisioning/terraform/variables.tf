variable "project_id" {
  description = "Google Cloud Platform Project ID"
  type        = string
}

variable "region" {
  description = "Google Cloud Platform Region"
  type        = string
  default     = "us-central1"
}

variable "zone" {
  description = "Google Cloud Platform Zone"
  type        = string
  default     = "us-central1-a"
}

variable "instance_name" {
  description = "Name of the Google Cloud Platform instance"
  type        = string
  default     = "newpush-lab"
}

variable "machine_type" {
  description = "Google Cloud Platform Machine Type"
  type        = string
  default     = "e2-medium"
}

variable "domain" {
  description = "Domain name for the lab"
  type        = string
  default     = ""
}

variable "acme_zerossl_hmac" {
  description = "ZeroSSL HMAC encoded value"
  type        = string
  sensitive   = true
}

variable "acme_zerossl_kid" {
  description = "ZeroSSL KID value"
  type        = string
  sensitive   = true
}

variable "crowdsec_bouncer" {
  description = "CrowdSec bouncer"
  type        = bool
}

variable "hcaptcha_site_key" {
  description = "hCaptcha site key"
  type        = string
  sensitive   = true
}
