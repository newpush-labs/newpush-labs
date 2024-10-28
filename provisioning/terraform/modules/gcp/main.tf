resource "google_compute_address" "static_ip" {
  name = "${var.instance_name}-ip"
  region = var.region
}

resource "google_compute_firewall" "allow_http_https" {
  name    = "${var.instance_name}-allow-http-https"
  network = "default"

  allow {
    protocol = "tcp"
    ports    = ["80", "443"]
  }

  source_ranges = ["0.0.0.0/0"]
  target_tags   = ["http-server", "https-server"]
}

data "google_compute_subnetwork" "default" {
  name    = "default"
  region  = var.region
  project = var.project_id
}

resource "google_compute_instance" "newpush_lab" {
  name         = var.instance_name
  machine_type = var.machine_type
  zone         = var.zone

  tags = ["http-server", "https-server"]

  boot_disk {
    initialize_params {
      image = var.disk_image
      size  = var.disk_size
      type  = var.disk_type
    }
  }

  network_interface {
    network    = "default"
    subnetwork = data.google_compute_subnetwork.default.self_link
    access_config {
      nat_ip = google_compute_address.static_ip.address
    }
  }

  metadata = {
    user-data = var.cloud_init_config
  }

  # Allow stopping the instance to update properties
  allow_stopping_for_update = true

  # Use service account with minimal required permissions
  service_account {
    scopes = ["cloud-platform"]
  }
}
