resource "google_compute_network" "vpc_network" {
  name                    = "network-fredr"
  auto_create_subnetworks = false
  mtu                     = 1480
}

resource "google_compute_subnetwork" "default" {
  name          = "subnet-fredr"
  ip_cidr_range = "10.100.88.0/24"
  region        = "northamerica-northeast2"
  network       = google_compute_network.vpc_network.id
}

resource "google_compute_firewall" "int-subnet" {
  name = "allow-int-subnet-fredr"
  allow {
    protocol = "all"
  }
  direction     = "INGRESS"
  network       = google_compute_network.vpc_network.id
  priority      = 1000
  source_ranges = ["10.100.88.0/24", "10.46.0.0/17", "10.42.0.0/15"]
  target_tags   = ["allow-subnet"]
}

resource "google_compute_firewall" "trust-services" {
  name = "allow-trust-services-fredr"
  allow {
    ports    = [443]
    protocol = "tcp"
  }
  direction     = "INGRESS"
  network       = google_compute_network.vpc_network.id
  priority      = 1050
  source_ranges = ["0.0.0.0/0"]
  target_tags   = ["allow-trust-services"]
}

resource "google_compute_firewall" "parslab" {
  name = "allow-parslab-fredr"
  allow {
    ports    = [22, 443, 6443]
    protocol = "tcp"
  }
  allow {
    protocol = "icmp"
  }
  direction     = "INGRESS"
  network       = google_compute_network.vpc_network.id
  priority      = 1100
  // arbitrary networks for trusted-nets like a lab
  source_ranges = ["99.99.99.99/29"]
  target_tags   = ["allow-parslab"]
}

