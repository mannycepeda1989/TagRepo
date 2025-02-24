################################
# CONTAINER CLUSTER
#################################

resource "google_container_cluster" "primary" {
  project    = var.project_id
  name     = var.cluster_name
  location = var.location
  network = var.network
  subnetwork = var.subnetwork
  binary_authorization {
    evaluation_mode = var.binary_authorization_evaluation_mode
  }
#  min_master_version = "1.12"
  workload_identity_config {
     workload_pool = "${data.google_project.project.project_id}.svc.id.goog"
  }
  release_channel {
    channel = "UNSPECIFIED"
  }
  # We can't create a cluster with no node pool defined, but we want to only use
  # separately managed node pools. So we create the smallest possible default
  # node pool and immediately delete it.
  remove_default_node_pool = true
  master_auth {
     client_certificate_config {
        issue_client_certificate = true
     }
  }
  master_authorized_networks_config {
  dynamic "cidr_blocks" {
    for_each = var.cluster_master_authorized_cidr_blocks
      content {
        cidr_block   = cidr_blocks.value
        display_name =  cidr_blocks.key
      }
    }
  }
  ip_allocation_policy {
     services_ipv4_cidr_block = var.services_cidr
     cluster_ipv4_cidr_block  = var.pods_cidr
  }
  initial_node_count       = 1
  enable_shielded_nodes = true
  private_cluster_config {
      enable_private_nodes    = "true"
      enable_private_endpoint = "true"
      master_ipv4_cidr_block  = var.cluster_master_ipv4_cidr_block
  }
  database_encryption {
    state    = "ENCRYPTED"
    key_name = "projects/${var.project_id}/locations/${var.region}/keyRings/${var.gcs_kms_key_ring_name}/cryptoKeys/${var.gcs_kms_crypto_name}"
  }
  addons_config {
    gke_backup_agent_config {
      enabled = var.gke_backup_agent_config
    }
  }
}

################################
# CONTAINER NODE POOL
#################################

resource "google_container_node_pool" "primary_preemptible_nodes" {
  for_each = var.node_pools
  project    = var.project_id
  name       = each.key
  location   = var.location
  cluster    = google_container_cluster.primary.name
 # initial_node_count = each.value.min_count
  node_config {
    disk_size_gb = each.value.disk_size_gb
    disk_type    = each.value.disk_type
    machine_type = each.value.machine_type
    labels = var.labels
    shielded_instance_config {
      enable_secure_boot = var.shielded_enable_secure_boot
      enable_integrity_monitoring = var.shielded_enable_integrity_monitoring
    }
#  workload_identity_config {
#     workload_pool = "${data.google_project.project.project_id}.svc.id.goog"
#  }
    workload_metadata_config {
        mode = "GKE_METADATA"
     }
    # Google recommends custom service accounts that have cloud-platform scope and permissions granted via IAM Roles.
    service_account = data.google_service_account.service_account.email
    oauth_scopes    = var.node_pool_oauth_scopes
    preemptible     = var.preemptible
    metadata        = merge({"disable-legacy-endpoints" = "true"},var.metadata)
    tags            = var.node_config_tags
  }
  management {
      auto_repair = true
      auto_upgrade = var.auto_upgrade
  }
  autoscaling {
    min_node_count = var.autoscaling_min_node_count
    max_node_count = var.autoscaling_max_node_count
  }
}
