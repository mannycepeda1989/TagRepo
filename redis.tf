#############################################################
# REDIS INSTANCE
#############################################################

resource "google_sql_database_instance" "db_instance" {
  provider = google-beta

  project          = var.project_id
  name             = var.sql_db_instance_name
  database_version = var.sql_db_instance_version
  region           = var.region
 
  encryption_key_name = data.google_kms_crypto_key.gcs_kms_crypto_key.id
  deletion_protection = var.sql_db_instance_deletion_protection

  settings {
    tier = var.sql_db_instance_tier
    user_labels = var.sql_db_instance_labels
    
    ip_configuration {
      ipv4_enabled    = false
      require_ssl = true
      private_network = data.google_compute_network.vpc.id
    }

    backup_configuration {
      enabled = true
    }

  }
  depends_on = [google_service_networking_connection.sql_db_private_service_connection]
}

##################################################################
# VPC - PRIVATE SERVICE CONNECTION
#################################################################

resource "google_service_networking_connection" "sql_db_private_service_connection" {
  provider = google-beta
  network                 = data.google_compute_network.vpc.id
  service                 = "servicenetworking.googleapis.com"
  reserved_peering_ranges = [var.sql_db_private_ip_alloc_name]
}

#############################################################
# SQL DATABASE
#############################################################

resource "google_sql_database" "db" {
  provider  = google-beta
  project   = var.project_id
  name      = var.sql_db_name
  instance  = google_sql_database_instance.db_instance.name
}

