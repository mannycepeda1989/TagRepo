data "google_compute_network" "network" {
  name    = var.network
  project = var.project_id
}

provider "google" {
  credentials = fileexists(var.google_credentials) ? file(var.google_credentials) : ""
  region      = var.region
  project     = var.project_id
}

data "google_compute_subnetwork" "subnet" {
  name    = var.subnet
  project = var.project_id
  region  = var.region
}

resource "google_compute_disk" "data-disk" {
  count   = var.num_of_instances
  name    = "${var.prefix}-${var.zones[count.index % length(var.zones)]}-${count.index + 1}-data-disk"
  project = var.project_id
  zone    = var.zones[count.index % length(var.zones)]
  size    = var.data_disk_size
  type    = var.data_disk_type

  labels = var.labels
}

resource "google_compute_disk" "log-disk" {
  count   = var.num_of_instances
  name    = "${var.prefix}-${var.zones[count.index % length(var.zones)]}-${count.index + 1}-log-disk"
  project = var.project_id
  zone    = var.zones[count.index % length(var.zones)]
  size    = var.log_disk_size
  type    = var.log_disk_type

  labels = var.labels
}

resource "google_compute_instance" "vm_instance" {
  count                     = var.num_of_instances
  name                      = "${var.prefix}-${count.index + 1}"
  machine_type              = var.machine_type
  zone                      = var.zones[count.index % length(var.zones)]
  project                   = var.project_id
  allow_stopping_for_update = var.allow_stopping
  tags                      = var.tags
  labels                    = var.labels
  metadata                  = var.metadata
  can_ip_forward            = var.ipforward
  # Boot disk
  boot_disk {
    initialize_params {
      size  = var.boot_disk_size
      type  = var.boot_disk_type
      image = var.image
    }
  }

  attached_disk {
    source      = google_compute_disk.data-disk.*.name[count.index]
    device_name = "data"
    mode        = "READ_WRITE"
  }

  attached_disk {
    source      = google_compute_disk.log-disk.*.name[count.index]
    device_name = "log"
    mode        = "READ_WRITE"
  }

  network_interface {
    network    = data.google_compute_network.network.self_link
    subnetwork = data.google_compute_subnetwork.subnet.self_link
  }

  service_account {
    email  = var.service_account
    scopes = var.service_account_scope
  }

  metadata_startup_script = var.metadata_startup_script
  metadata = {
    block-project-ssh-keys = true
  }
}
