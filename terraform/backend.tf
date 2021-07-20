terraform {
  backend "s3" {
    bucket = "dfds-datacatalogue-terraform-emcla"
    key = "terraform"
    region = "eu-central-1"
  }
}