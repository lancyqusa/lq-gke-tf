data "http" "myip" {
  url = "https://api.ipify.org"
}

resource "google_compute_network" "gke_vpc" {
  project                 = var.gcp_project_id
  name                    = var.gcp_vpc_name
  description             = "GKE lab VPC"
  routing_mode            = "GLOBAL"
  auto_create_subnetworks = "false"
}

resource "google_compute_subnetwork" "gke_vpc_subnetwork" {
  project                  = var.gcp_project_id
  name                     = "${google_compute_network.gke_vpc.name}-node-${var.gcp_region}-subnet"
  ip_cidr_range            = var.gcp_node_cidr_range # local.lcl_node_cidr_range
  region                   = var.gcp_region
  network                  = google_compute_network.gke_vpc.self_link
  private_ip_google_access = true
  secondary_ip_range = [{
    ip_cidr_range = var.gcp_pod_cidr_range
    range_name    = var.gcp_pod_range_name
    },
    {
      ip_cidr_range = var.gcp_svcs_cidr_range
      range_name    = var.gcp_svcs_range_name
  }]
}

resource "google_compute_subnetwork" "gke_master_auth_subnetwork" {
  project                  = var.gcp_project_id
  name                     = "${google_compute_network.gke_vpc.name}-master-auth-${var.gcp_region}-subnet"
  ip_cidr_range            = var.gcp_master_auth_cidr_range # local.lcl_master_auth_subnet
  region                   = var.gcp_region
  network                  = google_compute_network.gke_vpc.self_link
  private_ip_google_access = true
}

resource "google_compute_router" "gke_cloud_router" {
  project = var.gcp_project_id
  name    = "gke-${google_compute_network.gke_vpc.name}-${var.gcp_region}-rtr"
  region  = var.gcp_region
  network = google_compute_network.gke_vpc.self_link

  bgp {
    asn = 65000
  }
}

resource "google_compute_router_nat" "gke_nat_router" {
  project                            = var.gcp_project_id
  name                               = "gke-${google_compute_network.gke_vpc.name}-${var.gcp_region}-nat"
  router                             = google_compute_router.gke_cloud_router.name
  region                             = var.gcp_region
  nat_ip_allocate_option             = "AUTO_ONLY"
  source_subnetwork_ip_ranges_to_nat = "ALL_SUBNETWORKS_ALL_IP_RANGES"
  min_ports_per_vm                   = 2048
}

resource "google_compute_firewall" "allow_iap_ssh_to_bastion_nodes" {
  name = "${google_compute_instance.gke_bastion_vm.name}-${google_container_cluster.gke_cluster_01.name}-allow-iap"
  network = google_compute_network.gke_vpc.name
  allow {
    protocol = "tcp"
    ports = ["22"]
  }
  source_ranges = ["35.235.240.0/20"]
  target_tags = [local.lcl_bastion_vm_nw_tag, local.lcl_nodes_network_tag]
}