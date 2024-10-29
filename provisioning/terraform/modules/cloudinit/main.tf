locals {
  cloud_config = templatefile("${path.module}/templates/cloud-config.yaml.tpl", {
    lab_home           = var.lab_home
    external_ip        = var.external_ip
    domain            = var.domain
    acme_zerossl_hmac = var.acme_zerossl_hmac
    acme_zerossl_kid  = var.acme_zerossl_kid
    crowdsec_bouncer  = var.crowdsec_bouncer
    hcaptcha_site_key = var.hcaptcha_site_key
  })
}

data "cloudinit_config" "config" {
  gzip          = false
  base64_encode = false

  part {
    content_type = "text/cloud-config"
    content      = local.cloud_config
  }
}
