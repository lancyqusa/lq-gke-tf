resource "google_container_node_pool" "custom_node_pool" {
  for_each          = length(var.gcp_custom_node_pools_object) > 0 ? var.gcp_custom_node_pools_object : {}
  provider          = google
  name              = each.key
  project           = var.gcp_project_id
  location          = var.gcp_region
  node_locations    = var.node_locations
  cluster           = var.gcp_cluster_id
  node_count        = each.value.node_count
  max_pods_per_node = each.value.max_pods_per_node

  dynamic "autoscaling" {
    for_each = each.value.autoscaling == true ? [each.key] : []
    content {
      min_node_count = lookup(lookup(var.gcp_custom_node_pool_autoscaling, each.key), "min_node_count")
      max_node_count = lookup(lookup(var.gcp_custom_node_pool_autoscaling, each.key), "max_node_count")
    }
  }

  management {
    auto_upgrade = true
    auto_repair  = true
  }

  node_config {
    preemptible     = each.value.preemptible
    image_type      = each.value.image_type
    disk_size_gb    = each.value.disk_size_gb
    disk_type       = each.value.disk_type
    local_ssd_count = each.value.local_ssd_count
    machine_type    = each.value.machine_type
    tags            = each.value.tags
    labels          = each.value.labels
    service_account = each.value.service_account
    oauth_scopes    = each.value.oauth_scopes
  }

  lifecycle {
    ignore_changes = [
      node_config["tags"],
      cluster,
    ]
  }


}