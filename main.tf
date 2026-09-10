provider "google" {
  project = var.project_id
  region  = var.region
}

# ---------------
# --- NETWORK ---
# ---------------
resource "google_compute_network" "vpc_network" {
  name = "terraform-network"
}

resource "google_compute_firewall" "allow_http" {
  name        = "allow-http"
  description = "Allow incoming HTTP traffic"
  network     = google_compute_network.vpc_network.name

  allow {
    protocol = "tcp"
    ports    = ["${var.port}"]
  }

  source_ranges = ["0.0.0.0/0"]
  target_tags   = ["http-server"]
}

# -------------------------
# --- INSTANCE TEMPLATE ---
# -------------------------
resource "google_compute_instance_template" "template" {
  name         = "vm-template"
  machine_type = "e2-micro"
  tags         = ["http-server"]

  disk {
    source_image = "debian-cloud/debian-13"
    auto_delete  = true
    boot         = true
  }

  network_interface {
    network = google_compute_network.vpc_network.name
    access_config {}
  }

  metadata_startup_script = <<-EOF
    #!/bin/bash
    apt-get update
    apt-get install -y busybox
    echo "Hello, World!" > index.html
    nohup busybox httpd -f -p ${var.port} &
  EOF
}

resource "google_compute_health_check" "autohealing" {
  name                = "autohealing-health-check"
  check_interval_sec  = 5
  timeout_sec         = 5
  healthy_threshold   = 2
  unhealthy_threshold = 10

  http_health_check {
    request_path = "/"
    port         = tostring(var.port)
  }
}

resource "google_compute_region_instance_group_manager" "appserver" {
  name               = "appserver-igm"
  base_instance_name = "app"
  region             = var.region

  version {
    instance_template = google_compute_instance_template.template.self_link_unique
  }

  named_port {
    name = "http"
    port = var.port
  }

  auto_healing_policies {
    health_check      = google_compute_health_check.autohealing.id
    initial_delay_sec = 300
  }
}

resource "google_compute_region_autoscaler" "appserver" {
  name   = "appserver-autoscaler"
  region = var.region
  target = google_compute_region_instance_group_manager.appserver.id

  autoscaling_policy {
    max_replicas    = 10
    min_replicas    = 2
    cooldown_period = 60

    cpu_utilization {
      target = 0.6
    }
  }
}

# -------------------------
# ----- LOAD BALANCER -----
# -------------------------
resource "google_compute_backend_service" "default" {
  name                  = "app-backend-service"
  protocol              = "HTTP"
  port_name             = "http"
  timeout_sec           = 10
  health_checks         = [google_compute_health_check.autohealing.id]
  load_balancing_scheme = "EXTERNAL_MANAGED"

  backend {
    group           = google_compute_region_instance_group_manager.appserver.instance_group
    balancing_mode  = "UTILIZATION"
    capacity_scaler = 1.0
  }
}

resource "google_compute_url_map" "default" {
  name            = "app-url-map"
  default_service = google_compute_backend_service.default.id
}

resource "google_compute_target_http_proxy" "default" {
  name    = "app-http-proxy"
  url_map = google_compute_url_map.default.id
}

resource "google_compute_global_forwarding_rule" "default" {
  name                  = "app-forwarding-rule"
  target                = google_compute_target_http_proxy.default.id
  port_range            = "80"
  load_balancing_scheme = "EXTERNAL_MANAGED"
}
