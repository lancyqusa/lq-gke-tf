variable "gcp_project_id" {
    type = string
    description = "(optional) describe your variable"
    default = "lq-sada-kms-demo"
}

variable "gcp_credentials" {
  type = string
  description = "(optional) describe your variable"
}

variable "gcp_region" {
    type = string
    description = "(optional) describe your variable"
    default = "us-central1"
}

variable "gcp_zone" {
    type = string
    description = "(optional) describe your variable"
    default = "us-central1-b"
}

# GKE Networking variables
variable "gcp_vpc_name" {
  default = "gke-vpc"
  description = "name of the VPC to be created, this is then concatenated with the gcp_region to generate the subnet name"
}

variable "gcp_pod_range_name" {
  default = "gke-pod-01"
}

variable "gcp_svcs_range_name" {
  default = "gke-svcs-01"
}

# Refer https://cloud.google.com/kubernetes-engine/docs/concepts/alias-ips#defaults_limits 
variable "gcp_node_cidr_range" {
  default = "172.16.0.0/23" # 512 - 4 (reserved for GKE ) = 508 nodes
}

variable "gcp_svcs_cidr_range" {
  default = "172.16.2.0/23" # 512 services
}

variable "gcp_pod_cidr_range" {
  default = "192.168.0.0/17" # 508 * ( lcl_max_pods_per_nodes * 2 ) = 508 * 60 = 32,768 pods = /17
}

variable "gcp_master_auth_cidr_range" {
    default = "10.1.0.0/24"    # Authorized network to access master
}

variable "gcp_master_cidr_range" {
    type = string
    description = "CIDR range to host the master control plane"
    default = "10.128.0.0/28"
}

variable "gcp_max_pods_per_node" {
    type = number
    default = 30
    description = "(optional) describe your variable"
}

# Other GKE variables
variable "gcp_gke_node_machine_type" {
    type = string
    default = "e2-medium"
    description = "(optional) describe your variable"
}

variable "gcp_cluster_name" {
    type = string
    description = "Name for the cluster"
    default = "gke-cluster-01"
}

variable "gcp_master_global_access_config" {
    type = bool
    description = "Indicate if the the private cluster master endpoint needs to be accessible across regions"
    default = false
}

variable "gcp_gke_node_pool_name" {
    type = string
    default = "gke-node-pool-01"
    description = "(optional) describe your variable"
}