gcp_region = "us-central1"
gcp_labels = {}
gcp_custom_node_pools_object = {
  "custom-pool" = {
    node_count        = 1
    max_pods_per_node = 30
    preemptible       = false
    image_type        = "COS_CONTAINERD"
    disk_size_gb      = 50
    disk_type         = "pd-standard"
    local_ssd_count   = 0
    machine_type      = "e2-micro"
    tags              = ["custom-pool-tag-01"]
    autoscaling       = true
    min_node_count    = 1
    max_node_count    = 1
    service_account = "gke-clus-comp-svc-acc-01@lq-sada-kms-demo.iam.gserviceaccount.com"
    oauth_scopes = [
      "https://www.googleapis.com/auth/cloud-platform"
    ]
  },
  "other-pool" = {
    node_count        = 2
    max_pods_per_node = 30
    preemptible       = false
    image_type        = "COS_CONTAINERD"
    disk_size_gb      = 50
    disk_type         = "pd-standard"
    local_ssd_count   = 0
    machine_type      = "e2-micro"
    tags              = ["other-pool-tag-01", "other-pool-tag-02"]
    autoscaling       = false
    min_node_count    = 1
    max_node_count    = 1
    service_account = "gke-clus-comp-svc-acc-01@lq-sada-kms-demo.iam.gserviceaccount.com"
    oauth_scopes = [
      "https://www.googleapis.com/auth/cloud-platform"
    ]
  },
}

gcp_custom_node_pool_autoscaling = {
  "custom-pool" = {
    name           = "custom-pool"
    min_node_count = 3
    max_node_count = 6
  },
  "other-pool" = {
    name           = "custom-pool"
    min_node_count = 6
    max_node_count = 12
  },
}


# gcp_custom_node_pool_autoscaling = {
#     {
#         name = "custom-pool"
#         min_node_count = 3
#         max_node_count = 6
#     },
#     {
#         name = "other-pool"
#         min_node_count = 20
#         max_node_count = 60
#     }
# }
# gcp_custom_node_pools_object = {}