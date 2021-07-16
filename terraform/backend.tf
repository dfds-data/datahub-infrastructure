terraform {
  backend "s3" {
    bucket = "dfds-datacatalogue-terraform"
    key = "terraform"
    region = "eu-central-1"
  }
}