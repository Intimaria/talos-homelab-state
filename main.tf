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

# Scoped credentials for the talos-tofu backend: full access to the
# tofu-state bucket, nothing else. Root creds stay in this repo only.
resource "minio_iam_user" "tofu_state" {
  name          = "tofu-state"
  force_destroy = true
}

resource "minio_iam_policy" "tofu_state" {
  name = "tofu-state-rw"
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = ["s3:ListBucket"]
        Resource = [minio_s3_bucket.tofu_state_bucket.arn]
      },
      {
        # DeleteObject is needed for the .tflock object (use_lockfile)
        Effect   = "Allow"
        Action   = ["s3:GetObject", "s3:PutObject", "s3:DeleteObject"]
        Resource = ["${minio_s3_bucket.tofu_state_bucket.arn}/*"]
      }
    ]
  })
}

resource "minio_iam_user_policy_attachment" "tofu_state" {
  user_name   = minio_iam_user.tofu_state.name
  policy_name = minio_iam_policy.tofu_state.id
}

output "tofu_state_access_key" {
  value = minio_iam_user.tofu_state.name
}

output "tofu_state_secret_key" {
  value     = minio_iam_user.tofu_state.secret
  sensitive = true
}
