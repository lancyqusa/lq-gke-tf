# terraform {
#   backend "gcs" {
#     bucket = "lq-tf-state-bucket"
#     prefix = "terraform-state/sadasystems-noobs-anthos-gke-lab"
#   }
# }

terraform {
  cloud {
    organization = "lancyq-sada"

    workspaces {
      name = "optoro-gke-test"
    }
  }
}