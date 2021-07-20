# Usage

Edit "terraform.backend.s3.bucket" in terraform/backend.tf to be an unique value(S3 naming limitation)

```bash
cd terraform
terraform init
terraform apply -var 'es_username=superuser' -var 'es_password=super-secure-password'
```
