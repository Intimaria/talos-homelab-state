

# Talos MinIO Backend

Terraform/OpenTofu configuration to provision a MinIO S3 bucket (`tofu-state`) for use as a Terraform backend with Talos on Proxmox.

This repository sets up the initial MinIO infrastructure that will store your Terraform state files. The secrets (MinIO endpoint, credentials) are encrypted with SOPS using age encryption.

## What This Does

- Creates a private S3 bucket named `tofu-state` in MinIO
- Uses SOPS to securely manage MinIO credentials
- Configures the MinIO provider via encrypted secrets
- Prepares the backend storage for Talos Kubernetes cluster state management

> [!warning] State Management
> This repository stores its own state **locally** in `terraform.tfstate` (not in MinIO). This is intentional - it's a bootstrap repository that creates the MinIO backend itself.
> 
> **The state file contains sensitive data** (MinIO credentials in plaintext). You can encrypt it with SOPS and commit it to version control, then decrypt when using Tofu locally. **Never commit it as plaintext.** If you lose the state, you can reimport: `tofu import minio_s3_bucket.tofu_state_bucket tofu-state`

## Requirements

Install the following tools:

```bash
# On Debian/Ubuntu
sudo apt update
sudo apt install -y age sops 

# You'll also need OpenTofu (or Terraform) and Direnv
# Install from: https://opentofu.org/docs/intro/install/ and https://direnv.net/

```

Required tools:
- **age** - Encryption tool for generating keys and encrypting secrets
- **sops** - Secrets manager that integrates with age
- **direnv** - Loads environment variables automatically (sets `SOPS_AGE_KEY_FILE`)
- **tofu** - OpenTofu CLI (or use `terraform` if you prefer)

## Initial Setup

### 1. Generate age encryption key

Create an age keypair for encrypting your secrets:

```bash
mkdir -p .age
age-keygen > .age/keys.txt
chmod 600 .age/keys.txt
```

**Important**: The `.age/` directory is gitignored. Keep your private key secure and never commit it to version control.

### 2. Update SOPS configuration

The `.sops.yaml` file contains the age public key used for encryption. Update it with your public key:

```bash
# Extract your public key
grep "public key:" .age/keys.txt

# Update .sops.yaml with your public key
vim .sops.yaml
```

Example `.sops.yaml`:
```yaml
creation_rules:
    - age: >-
        age1your_public_key_here
```

### 3. Create and encrypt secrets

Edit `secrets.sops.example.yaml` file with your MinIO connection details

# Encrypt it in-place with sops
```bash
sops -e -i secrets.sops.example.yaml
mv secrets.sops.example.yaml secrets.sops.yaml
```

The file will now be encrypted. To edit it later:
```bash
sops secrets.sops.yaml
```

### 4. Enable direnv

The `.envrc` file automatically sets the `SOPS_AGE_KEY_FILE` environment variable:

```bash
direnv allow .
```

This ensures SOPS can decrypt your secrets automatically.

## Deploy the MinIO Bucket

Initialize and apply the Terraform configuration:

```bash
# Initialize providers
tofu init

# Review the plan
tofu plan

# Create the bucket
tofu apply
```

After successful deployment, you'll have a `tofu-state` bucket in MinIO ready to use as a Terraform backend.

## Using This Backend in Other Projects

Once deployed, configure other Terraform projects to use this bucket as a backend:

```hcl
terraform {
  backend "s3" {
    bucket   = "tofu-state"
    key      = "path/to/my/project.tfstate"
    endpoint = "http://your-minio-server:9000"
    
    skip_credentials_validation = true
    skip_metadata_api_check     = true
    skip_region_validation      = true
    use_path_style            = true
    
    region = "us-east-1"  # Required but not used by MinIO
  }
}
```

Set credentials via environment variables:
```bash
export AWS_ACCESS_KEY_ID="your-minio-user"
export AWS_SECRET_ACCESS_KEY="your-minio-password"
```

## Repository Structure

```
.
├── main.tf              # MinIO bucket resource definition
├── providers.tf         # Provider configuration 
├── secrets.sops.yaml    # Encrypted MinIO credentials
├── .sops.yaml           # SOPS encryption configuration
├── .envrc               # Direnv config for SOPS_AGE_KEY_FILE
├── .age/                # Directory for age private keys 
└── README.md            # This file
```


## Related Documentation

- [OpenTofu S3 Backend](https://opentofu.org/docs/language/settings/backends/s3/)
- [MinIO Terraform Provider](https://registry.terraform.io/providers/aminueza/minio/latest/docs)
- [SOPS Documentation](https://github.com/getsops/sops)
- [age Encryption](https://github.com/FiloSottile/age)
