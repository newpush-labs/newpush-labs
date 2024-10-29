variable "lab_home" {
  description = "Installation directory for newpush-lab"
  type        = string
  default     = "/opt/newpush-lab"
}

variable "external_ip" {
  description = "External IP address"
  type        = string
}

variable "domain" {
  description = "Domain name for the lab"
  type        = string
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