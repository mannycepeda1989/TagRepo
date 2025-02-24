################################################
# MANAGED INSTANCE GROUP
################################################

resource "google_compute_instance_group_manager" "mig" {
  provider         = google
  project            = var.project_id
  name               = var.mig_name
  description        = var.mig_description 
  zone               = var.mig_zone
  target_pools       = [google_compute_target_pool.target_pool.self_link]
  base_instance_name = var.mig_base_instance_name

  list_managed_instances_results = var.mig_list_managed_instances_results

  version {
    name              = var.mig_version_name
    instance_template = data.google_compute_instance_template.instance_template.self_link
    #target_size {
    #  fixed = var.mig_version_target_size_fixed
    #}
  }

  auto_healing_policies {
    health_check      = google_compute_http_health_check.health_check.id
    initial_delay_sec = var.auto_healing_policies_time
  }

  #instance_lifecycle_policy {
  #  force_update_on_repair = var.instance_lifecycle_policy
  #}

  named_port {
    name = var.mig_named_port_name
    port = var.mig_named_port_port
  }

  depends_on = [
    google_compute_target_pool.target_pool,
    google_compute_http_health_check.health_check
  ]
}
