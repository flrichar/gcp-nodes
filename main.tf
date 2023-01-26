// create .env file in local working-dir

provider "google" {
  project = "rancher-support-01"
  region  = "northamerica-northeast2"
  zone    = "northamerica-northeast2-c"
}

resource "google_compute_instance" "default" {
  for_each = toset(["node074", "node075"])

  name         = "fredr-${each.key}"
  machine_type = "n1-standard-2"
  zone         = "northamerica-northeast2-c"

  labels = {
    owner       = "fredr"
    donotdelete = "true"
  }

  // Network
  tags = ["allow-parslab", "allow-subnet", "allow-trust-services"]

  boot_disk {
    initialize_params {
      image = "ubuntu-os-cloud/ubuntu-2004-lts"
      size  = 64
      type  = "pd-balanced"
    }
  }

  // Local SSD disk, makes good lh-scratch disk
  scratch_disk {
    interface = "NVME"
  }

  network_interface {
    subnetwork = google_compute_subnetwork.default.id

    access_config {
      // Ephemeral public IP, future-use
    }
  }

  metadata = {
    sshKeys = "ubuntu:${file(var.ssh_public_key_filepath)}"
  }
  metadata_startup_script = "echo FredR > /ownerinfo.txt"

}

variable "ssh_public_key_filepath" {
  description = "Filepath for the ssh public key"
  type        = string
  
  // symlinked in local working dir
  default = "sshkey.pub"
}

