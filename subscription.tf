###############################################
# PUBSUB SUBSCRIPTIONS
###############################################

resource "google_pubsub_lite_subscription" "subscription" {
  name     = var.subscription_name
  topic    = var.pubsublitetopic_name
  project  = var.project_id
  region   = var.region
  zone    = var.zone
  delivery_config {
    delivery_requirement = var.subscription_delivery_requirement
  }

  depends_on = [google_pubsub_lite_topic.pubsublitetopic]
}
