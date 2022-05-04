locals {
  # lcl_project_id     = "sada-anthos-labs"
  lcl_network           = google_compute_network.gke_vpc.name
  lcl_subnetwork        = google_compute_subnetwork.gke_vpc_subnetwork
  lcl_gcp_cp_cidr_range = join(".", [element(split(".", data.google_container_cluster.my_cluster.endpoint), 0), element(split(".", data.google_container_cluster.my_cluster.endpoint), 1), element(split(".", data.google_container_cluster.my_cluster.endpoint), 2), "0/28"])
  # -- commented 12/29 region             = "us-central1" 
  # -- commented 12/29 lcl_machine_type   = "e2-standard-4"
  # -- commented 12/29 lcl_node_pool_name = "lq-node-pool-01"

  # Refer https://cloud.google.com/kubernetes-engine/docs/concepts/alias-ips#defaults_limits 
  # -- commented 12/29 lcl_node_cidr_range     = "172.16.0.0/23"  # 512 - 4 (reserved for GKE ) = 508 nodes
  # -- commented 12/29 lcl_svcs_cidr_range     = "172.16.2.0/23"  # 512 services
  # -- commented 12/29 lcl_pod_cidr_range      = "192.168.0.0/17" # 508 * ( lcl_max_pods_per_nodes * 2 ) = 508 * 60 = 32,768 pods = /17
  # -- commented 12/29 lcl_master_auth_subnet  = "10.1.0.0/24"    # Authorized network to access master
  # -- commented 12/29 lcl_master_ipv4_network = "10.2.0.0/28"    # Network to host master
  # -- commented 12/29 lcl_max_pods_per_node   = 30
  # lcl_cluster_name = "lq-anthos-gke-cluster-01"
  lcl_nodes_network_tag = "gke-${var.gcp_cluster_name}-tag"
  #   service_account = {
  #     email  = module.vctr_svc_acc.email
  #     scopes = ["https://www.googleapis.com/auth/cloud-platform"]
  #   }

}

# Commented on 2/26/2022 as this svc account relates to Anthos component installs
# module "anthos_install_svc_acc" {
#   source        = "terraform-google-modules/service-accounts/google"
#   version       = "~> 3.0"
#   project_id   = var.gcp_project_id
#   display_name = "lancy's Anthos TF service account"  
#   prefix       = "gke-tf"
#   names        = ["svc-acc-01"]
#   project_roles = [
#     "${var.gcp_project_id}=>roles/gkehub.admin",
#     "${var.gcp_project_id}=>roles/iam.serviceAccountKeyAdmin",
#     "${var.gcp_project_id}=>roles/resourcemanager.projectIamAdmin",
#     "${var.gcp_project_id}=>roles/container.admin",
#   ]
# }



# Assign minimum set of roles for GKE cluster default compute service account
module "gke_def_comp_svc_acc" {
  source       = "terraform-google-modules/service-accounts/google"
  version      = "~> 3.0"
  project_id   = var.gcp_project_id
  display_name = "GKE Default compute service account for nodes"
  prefix       = "gke-clus"
  names        = ["comp-svc-acc-01"]
  project_roles = [
    "${var.gcp_project_id}=>roles/logging.logWriter",                   # Minimum set of roles for a GKE service account
    "${var.gcp_project_id}=>roles/monitoring.metricWriter",             # Minimum set of roles for a GKE service account
    "${var.gcp_project_id}=>roles/monitoring.viewer",                   # Minimum set of roles for a GKE service account
    "${var.gcp_project_id}=>roles/stackdriver.resourceMetadata.writer", # Minimum set of roles for a GKE service account
  ]
}

## Assign roles/storage.objectViewer to the GCS that has the images for the nodes to pull images from Container Registry
## artifacts.PROJECT-ID.appspot.com for images stored on the host gcr.io
## STORAGE-REGION.artifacts.PROJECT-ID.appspot.com for images stored on other registry hosts

resource "google_storage_bucket_iam_member" "gcr_io_image_pull_iam" {
  bucket = "artifacts.${var.gcp_project_id}.appspot.com"
  role   = "roles/storage.objectViewer"
  member = module.gke_def_comp_svc_acc.iam_email
}


resource "google_container_cluster" "gke_cluster_01" {
  ### General cluster parameters
  name     = var.gcp_cluster_name
  project  = var.gcp_project_id
  location = var.gcp_region
  provider = google-beta

  default_max_pods_per_node = var.gcp_max_pods_per_node # local.lcl_max_pods_per_node
  description               = "Sandbox GKE cluster"
  node_locations            = ["us-central1-a", "us-central1-b", "us-central1-c"]
  lifecycle {
    ignore_changes = [
      node_config["tags"]
    ]
  }
  private_cluster_config {
    enable_private_endpoint = true
    master_ipv4_cidr_block  = var.gcp_master_cidr_range # local.lcl_master_ipv4_network
    enable_private_nodes    = true
    master_global_access_config {
      enabled = var.gcp_master_global_access_config
    }
  }

  ### Cluster networking
  networking_mode = "VPC_NATIVE"
  network         = google_compute_network.gke_vpc.self_link
  subnetwork      = google_compute_subnetwork.gke_vpc_subnetwork.self_link
  ip_allocation_policy {
    cluster_secondary_range_name  = lookup(google_compute_subnetwork.gke_vpc_subnetwork.secondary_ip_range[0], "range_name")
    services_secondary_range_name = lookup(google_compute_subnetwork.gke_vpc_subnetwork.secondary_ip_range[1], "range_name")
  }
  default_snat_status {
    disabled = false
  }
  master_authorized_networks_config {
    cidr_blocks {
      cidr_block   = var.gcp_master_auth_cidr_range # local.lcl_master_auth_subnet
      display_name = "gke-master-auth-subnet"
    }
  }

  ### Cluster options
  cluster_autoscaling {
    enabled = false
  }
  workload_identity_config {
    workload_pool = "${data.google_project.gke_project.project_id}.svc.id.goog" # changed from identity_namespace
  }

  ### Release channel options
  release_channel {
    channel = "REGULAR"
  }

  ### Cluster Node configuration
  node_config {
    workload_metadata_config {
      mode = "GKE_METADATA" # This must be enabled only when WL identity is enabled. # Changed from node_metadata = "GKE_METADATA_SERVER"
    }
  }

  ### Cluster add-ons
  addons_config {
    http_load_balancing { # Needed for ASM https://cloud.google.com/service-mesh/docs/iap-integration#setting_up_a_cluster_with_anthos_service_mesh
      disabled = false
    }
  }

  ### Cluster node pool configuration
  # We can't create a cluster with no node pool defined, but we want to only use
  # separately managed node pools. So we create the smallest possible default
  # node pool and immediately delete it.

  remove_default_node_pool = true
  initial_node_count       = 1 # No. of nodes/zone
  resource_labels = {
    cluster_owner = "lancy_quadros"
    mesh_id       = "proj-${data.google_project.gke_project.number}"
  }
}

resource "google_container_node_pool" "gke_node_pool_01" {
  name              = var.gcp_gke_node_pool_name # local.lcl_node_pool_name
  provider          = google-beta
  cluster           = google_container_cluster.gke_cluster_01.id
  node_count        = 1
  max_pods_per_node = var.gcp_max_pods_per_node # local.lcl_max_pods_per_node

  lifecycle {
    ignore_changes = [
      # node_config["tags"], 
      cluster,
    ]
  }
  autoscaling {
    min_node_count = 1
    max_node_count = 3
  }
  node_config {
    preemptible  = false
    image_type   = "COS_CONTAINERD"
    disk_size_gb = 50
    machine_type = var.gcp_gke_node_machine_type # local.lcl_machine_type

    tags = [local.lcl_nodes_network_tag]

    labels = {
      cluster        = google_container_cluster.gke_cluster_01.name,
      node_pool_name = var.gcp_gke_node_pool_name # local.lcl_node_pool_name
    }

    # Google recommends custom service accounts that have cloud-platform scope and permissions granted via IAM Roles.
    service_account = module.gke_def_comp_svc_acc.email
    oauth_scopes = [
      "https://www.googleapis.com/auth/cloud-platform"
    ]
  }
}

# module "custom-node-pool" {
#   source                           = "./modules/cluster-custom-node-pool"
#   gcp_project_id                   = var.gcp_project_id
#   gcp_region                       = var.gcp_region
#   gcp_labels = {
#     cluster = google_container_cluster.gke_cluster_01.name
#   }
#   gcp_cluster_id                   = google_container_cluster.gke_cluster_01.id
#   gcp_custom_node_pools_object     = var.gcp_custom_node_pools_object
#   gcp_custom_node_pool_autoscaling = var.gcp_custom_node_pool_autoscaling
# }