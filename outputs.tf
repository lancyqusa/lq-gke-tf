# output "gcp_cluster_output" {
#   value = data.google_container_cluster.my_cluster
# }

output "gcp_control_plane_cidr_range" {
  value = join(".", [element(split(".", data.google_container_cluster.my_cluster.endpoint), 0), element(split(".", data.google_container_cluster.my_cluster.endpoint), 1), element(split(".", data.google_container_cluster.my_cluster.endpoint), 2), "0/28"])
}

