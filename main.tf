// OpenTofu / Terraform configuration for GCP compute nodes
// Intended for use with Rancher Custom Cluster (RKE2 / K3S) pre-provisioned nodes

terraform {
  // Example: PostgreSQL-compatible backend (e.g. CockroachDB serverless, Supabase, etc.)
  // Configure connection via PG* environment variables or a .env file
  backend "pg" {
    // schema_name = "your-schema-name"
  }
}

provider "google" {
  project = var.project_id
  region  = var.region
  zone    = var.zone
}

locals {
  instance_names = toset(["node01", "node02", "node03", "node04"])
}

resource "google_compute_instance" "default" {
  for_each = local.instance_names

  name         = "${var.name_prefix}-${each.key}"
  machine_type = "n2d-standard-4"
  zone         = var.zone

  // Toggle instances running/stopped without destroying
  desired_status = var.instances_running ? "RUNNING" : "TERMINATED"

  labels = {
    owner       = var.owner
    donotdelete = "true"
    project-id  = var.project_label
  }

  // Network tags must match firewall rules in network.tf
  tags = ["allow-homelab", "allow-subnet", "allow-trust-services"]

  boot_disk {
    auto_delete = false // retain boot disk on instance deletion
    initialize_params {
      image = "debian-cloud/debian-13"
      size  = 67
      type  = "pd-balanced"
    }
  }

  // Ignore boot/attached disk changes to avoid instance replacement on OS upgrades
  lifecycle {
    ignore_changes = [boot_disk, attached_disk]
  }

  // Local NVMe SSD scratch disk (used for Longhorn experimentation)
  // Note: adding/removing scratch_disk forces instance replacement;
  // lifecycle ignore_changes above prevents unintended replacement
  scratch_disk {
    interface = "NVME"
  }

  // Spot instance configuration
  // nat_ip will change on every preemption — see outputs.tf
  scheduling {
    preemptible                 = true
    automatic_restart           = false
    provisioning_model          = "SPOT"
    instance_termination_action = "STOP"
  }

  network_interface {
    subnetwork = google_compute_subnetwork.default.id
    stack_type = "IPV4_IPV6"

    access_config {
      // Ephemeral public IP
    }
  }

  metadata = {
    sshKeys = "${var.ssh_user}:${file(var.ssh_public_key_filepath)}"
  }

  metadata_startup_script = "echo ${var.name_prefix} > /ownerinfo.txt"
}

// --- Variables ---

variable "project_id" {
  description = "GCP project ID"
  type        = string
}

variable "region" {
  description = "GCP region"
  type        = string
  default     = "northamerica-northeast2"
}

variable "zone" {
  description = "GCP zone for compute instances"
  type        = string
  default     = "northamerica-northeast2-b"
}

variable "name_prefix" {
  description = "Prefix applied to all named resources (instances, disks, etc.)"
  type        = string
  default     = "example"
}

variable "owner" {
  description = "Owner label applied to instances"
  type        = string
  default     = "example"
}

variable "project_label" {
  description = "Project label applied to instances"
  type        = string
  default     = "my-project"
}

variable "ssh_user" {
  description = "SSH username for instance metadata"
  type        = string
  default     = "debian"
}

variable "ssh_public_key_filepath" {
  description = "Filepath to the SSH public key"
  type        = string
  default     = "sshkey.pub"
}

variable "instances_running" {
  description = "Whether instances should be running (true) or stopped (false)"
  type        = bool
  default     = true
}


// --- Optional: additional disk attachment (commented out) ---
// Uncomment and adjust to attach additional persistent disks per node.
// lifecycle ignore_changes on attached_disk above prevents instance replacement.

//resource "google_compute_disk" "topo_disks" {
//  for_each = local.instance_names
//
//  name = "${var.name_prefix}-${each.key}-topodisk"
//  type = "pd-standard"
//  zone = var.zone
//  size = 20
//
//  labels = {
//    experiment = "topolvm-disks"
//    owner      = var.owner
//  }
//}
//
//resource "google_compute_attached_disk" "attachments" {
//  for_each    = local.instance_names
//  disk        = google_compute_disk.topo_disks[each.key].id
//  instance    = "${var.name_prefix}-${each.key}"
//  device_name = "topo-disk"
//  zone        = var.zone
//}
