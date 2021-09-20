# Configure Terragrunt to automatically store tfstate files in an S3 bucket
remote_state {
  backend = "s3"
  config = {
    bucket         = "dfds-datacatalogue-terraform"
    key            = "terraform"
    region         = "eu-central-1"
    encrypt        = true
    dynamodb_table = "datacatalogue-terraform-locks"
  }
}

# Indicate where to source the terraform module from.
terraform {
  source = "../../."
}

# Indicate the input values to use for the variables of the module.
inputs = {
  env = "prod"
}