variable "gcp_cluster_id" {}
variable "gcp_project_id" {}
variable "gcp_region" {}
variable "node_locations" {
  type    = list(string)
  default = ["us-central1-c", "us-central1-a", "us-central1-b"]
}

variable "gcp_custom_node_pools_object" {
  type = map(object({
    node_count        = number
    max_pods_per_node = number
    preemptible       = bool
    image_type        = string
    disk_size_gb      = number
    disk_type         = string
    local_ssd_count   = number
    machine_type      = string
    tags              = list(string)
    autoscaling       = bool
    min_node_count    = number
    max_node_count    = number
    labels = object({
      cluster        = string
      node_pool_name = string
    })
    service_account = string
    oauth_scopes    = list(string)
  }))
  default = {}
}

variable "gcp_custom_node_pool_autoscaling" {
  type = map(object({
    min_node_count = number
    max_node_count = number
    }
  ))
  description = "This variable will contain the list of node pools that will be autoscaled"
  default     = {}
}
