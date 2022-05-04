data "google_project" "gke_project" {
  project_id = var.gcp_project_id
}

data "google_container_cluster" "my_cluster" {
  name     = var.gcp_cluster_name
  location = var.gcp_region
}

# data "google_compute_instance" "gke_nodes" {
#   name = "${data.google_container_cluster.my_cluster.name}*"
# }