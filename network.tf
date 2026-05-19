// VPC network with dual-stack (IPv4/IPv6) support
resource "google_compute_network" "vpc_network" {
  name                     = "network-${var.name_prefix}"
  auto_create_subnetworks  = false
  enable_ula_internal_ipv6 = true
  mtu                      = 1480
}

// Dual-stack subnet with internal IPv6
resource "google_compute_subnetwork" "default" {
  name          = "subnet-${var.name_prefix}"
  ip_cidr_range = var.subnet_cidr
  region        = var.region
  network       = google_compute_network.vpc_network.id

  stack_type       = "IPV4_IPV6"
  ipv6_access_type = "INTERNAL"
}

// Allow all traffic within trusted internal subnets
resource "google_compute_firewall" "int-subnet" {
  name = "allow-int-subnet-${var.name_prefix}"
  allow {
    protocol = "all"
  }
  direction     = "INGRESS"
  network       = google_compute_network.vpc_network.id
  priority      = 1000
  source_ranges = concat([var.subnet_cidr], var.trusted_cidrs)
  target_tags   = ["allow-subnet"]
}

// Allow HTTPS from anywhere (e.g. Rancher UI, API endpoints)
resource "google_compute_firewall" "trust-services" {
  name = "allow-trust-services-${var.name_prefix}"
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

// Allow SSH, HTTPS, and Kubernetes API access from a trusted source IP
// Set var.trusted_source_ip to your homelab or VPN egress IP (e.g. "203.0.113.1/32")
// RFC 5737 documentation prefix used as placeholder — replace before apply
resource "google_compute_firewall" "homelab" {
  name = "allow-homelab-${var.name_prefix}"
  allow {
    ports    = [22, 443, 5000, 6443]
    protocol = "tcp"
  }
  allow {
    protocol = "icmp"
  }
  direction     = "INGRESS"
  network       = google_compute_network.vpc_network.id
  priority      = 1100
  source_ranges = [var.trusted_source_ip]
  target_tags   = ["allow-homelab"]
}

// --- Variables ---

variable "subnet_cidr" {
  description = "Primary IPv4 CIDR range for the subnet"
  type        = string
  default     = "10.100.88.0/24"
}

variable "trusted_cidrs" {
  description = "Additional internal CIDR ranges allowed through the subnet firewall (e.g. on-prem, VPN)"
  type        = list(string)
  default     = []
}

variable "trusted_source_ip" {
  description = "Trusted source IP/CIDR for homelab/VPN access (SSH, HTTPS, K8s API). No default — must be set explicitly."
  type        = string
  // No default: forces explicit declaration, prevents accidental open access
}
