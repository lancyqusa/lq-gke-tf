provider "google" {
  project     = var.gcp_project_id 
  region      = var.gcp_region
  zone        = var.gcp_zone
  credentials = var.gcp_credentials
}
provider "google-beta" {
  project     = var.gcp_project_id 
  region      = var.gcp_region
  zone        = var.gcp_zone
  credentials = var.gcp_credentials
}