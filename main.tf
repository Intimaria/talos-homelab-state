# File: main.tf
data "sops_file" "secrets" {
  source_file = "secrets.sops.yaml"
}

provider "minio" {
  minio_server   = data.sops_file.secrets.data["minio_endpoint"]
  minio_user     = data.sops_file.secrets.data["minio_user"]
  minio_password = data.sops_file.secrets.data["minio_password"]
}

resource "minio_s3_bucket" "tofu_state_bucket" {
  bucket = "tofu-state"
  acl    = "private"
}
