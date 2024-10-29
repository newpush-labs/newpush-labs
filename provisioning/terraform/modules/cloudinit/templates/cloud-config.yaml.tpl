#cloud-config

write_files:
  - path: /tmp/install.sh
    permissions: '0755'
    content: |
      #!/bin/bash
      export LAB_HOME="${lab_home}"
      export EXTERNAL_IP="${external_ip}"
      export DOMAIN="${domain}"
      export ACME_ZEROSSL_HMAC_ENCODED="${acme_zerossl_hmac}"
      export ACME_ZEROSSL_KID="${acme_zerossl_kid}"
      export CROWDSEC_BOUNCER="${crowdsec_bouncer}"
      export HCAPTCHA_SITE_KEY="${hcaptcha_site_key}"
      
      curl -s https://raw.githubusercontent.com/newpush-labs/newpush-labs/refs/heads/main/installer/newpush-lab-unattended.sh | bash

runcmd:
  - /tmp/install.sh
