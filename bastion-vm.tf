module "gke_compute_svc_acc" {
  source       = "terraform-google-modules/service-accounts/google"
  version      = "~> 3.0"
  project_id   = var.gcp_project_id
  display_name = "Bastion Compute service account"
  prefix       = "gke-bastion"
  names        = ["comp-svc-acc-01"]
  project_roles = [
    "${var.gcp_project_id}=>roles/container.admin",            # Need this to manage the cluster from the bastion vm
    "${var.gcp_project_id}=>roles/compute.admin",              # Need this to ssh to the nodes if needed - specifically - compute.instances.get is needed.
    "${var.gcp_project_id}=>roles/iam.serviceAccountUser",     # Need this to ssh to the nodes if needed - for IAP
    "${var.gcp_project_id}=>roles/iap.tunnelResourceAccessor", # Need this to ssh to the nodes if needed - for IAP
    #  "${var.gcp_project_id}=>roles/compute.instanceAdmin.v1" # Need this to ssh to the nodes if needed - This may be needed for IAP
  ]
}

locals {
  lcl_compute_svc_acc   = module.gke_compute_svc_acc.email
  lcl_bastion_vm_name   = "lq-gke-bastion-vm"
  lcl_zone              = "us-central1-c"
  lcl_bastion_vm_nw_tag = "bastion-vm"
}

resource "google_compute_instance" "gke_bastion_vm" {
  name         = local.lcl_bastion_vm_name
  machine_type = "e2-medium"
  zone         = local.lcl_zone
  tags         = [local.lcl_bastion_vm_nw_tag]
  network_interface {
    subnetwork = google_compute_subnetwork.gke_master_auth_subnetwork.self_link
    #    access_config {}
  }
  boot_disk {
    initialize_params {
      image = "debian-cloud/debian-10"
    }
  }
  service_account {
    email  = local.lcl_compute_svc_acc
    scopes = ["cloud-platform"]
  }
}