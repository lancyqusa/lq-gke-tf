module "project-services" {
  source  = "terraform-google-modules/project-factory/google//modules/project_services"

  project_id  = var.gcp_project_id # data.google_client_config.current.project
  disable_services_on_destroy = false
  activate_apis = [
    "compute.googleapis.com",
    "iam.googleapis.com",
    "container.googleapis.com",
    "cloudresourcemanager.googleapis.com",
    "cloudtrace.googleapis.com",
    "monitoring.googleapis.com",
    "logging.googleapis.com"
  ]
}