provider "google" {
  project = var.project_id
  region  = var.region
}

module "cloudinit" {
  source = "./modules/cloudinit"

  external_ip        = module.gcp.instance_ip
  domain            = var.domain
  acme_zerossl_hmac = var.acme_zerossl_hmac
  acme_zerossl_kid  = var.acme_zerossl_kid
  crowdsec_bouncer  = var.crowdsec_bouncer
  hcaptcha_site_key = var.hcaptcha_site_key
}

module "gcp" {
  source = "./modules/gcp"

  project_id        = var.project_id
  region           = var.region
  zone             = var.zone
  instance_name     = var.instance_name
  machine_type      = var.machine_type
  cloud_init_config = module.cloudinit.rendered_config
}
