// Set the cloud provider to AWS
provider "aws" {
  region = "eu-central-1"
}

terraform {
	# The configuration for this backend will be filled in by Terragrunt
	backend "s3" {}
	required_version = ">= 0.12"
}

locals {
  name = "datacatalogue"

  tags = {
    Name        = "datacatalogue"
    Environment = "${var.env}"
  }
}

// Networking

resource "aws_default_vpc" "default" {
  tags = local.tags
}
resource "aws_default_subnet" "default_az1" {
  availability_zone = "eu-central-1a"

  tags = {
    Name = "Default subnet for eu-central-1a"
  }
}
resource "aws_default_subnet" "default_az2" {
  availability_zone = "eu-central-1b"

  tags = {
    Name = "Default subnet for eu-central-1b"
  }
}
// RDS

module "security_group" {
  source  = "terraform-aws-modules/security-group/aws"
  version = "4.3.0"

  name        = "${local.name}-database-security-group"
  description = "${local.name} backend security group"
  vpc_id      = aws_default_vpc.default.id


  # ingress
  ingress_with_cidr_blocks = [
    {
      rule        = "mysql-tcp"
      cidr_blocks = "0.0.0.0/0"
    },
  ]
  tags = local.tags
}

module "db" {
  source  = "terraform-aws-modules/rds/aws"
  version = "5.9.0"

  identifier = local.name

  create_db_option_group    = false
  create_db_parameter_group = false

  # All available versions: https://docs.aws.amazon.com/AmazonRDS/latest/UserGuide/CHAP_PostgreSQL.html#PostgreSQL.Concepts
  engine                      = "mysql"
  engine_version              = "8.0"
  family                      = "mysql8.0" # DB parameter group
  instance_class              = "db.t3.micro"
  allow_major_version_upgrade = true

  allocated_storage     = 20
  max_allocated_storage = 50

  # NOTE: Do NOT use 'user' as the value for 'username' as it throws:
  # "Error creating DB Instance: InvalidParameterValue: MasterUsername
  # user cannot be used as it is a reserved word used by the engine"
  /* name                   = local.name */
  username               = "superuser"
  create_random_password = true
  random_password_length = 32
  port                   = 3306
  publicly_accessible    = true

  vpc_security_group_ids = [module.security_group.security_group_id]

  maintenance_window = "Mon:00:00-Mon:03:00"
  backup_window      = "03:00-06:00"

  backup_retention_period = 10

  subnet_ids = [aws_default_subnet.default_az1.id, aws_default_subnet.default_az2.id]
  tags       = local.tags
}

resource "aws_ssm_parameter" "database_password" {
  name        = "/${local.name}/db_credentials"
  description = "Password for the backend database for ${local.name}"
  type        = "SecureString"
  value = jsonencode({
    "username" = module.db.db_instance_username
    "password" = module.db.db_instance_password
    "host"     = module.db.db_instance_endpoint
    "port"     = module.db.db_instance_port
  })
  overwrite = true
}

// Elastic

resource "random_string" "es-unique-identifier" {
  length   = 5
  special  = false
  lower    = true
  upper    = false
  numeric  = true
}

module "es-password" {
  source   = "./modules/password"
  ssm_path = "/${local.name}/elasticsearch/password"
}

resource "aws_elasticsearch_domain" "datahub-es" {
  domain_name           = "datahub-${random_string.es-unique-identifier.result}"
  tags                  = local.tags
  elasticsearch_version = "7.10"
  domain_endpoint_options {
    enforce_https       = true
    tls_security_policy = "Policy-Min-TLS-1-0-2019-07"
  }
  node_to_node_encryption {
    enabled = true
  }

  access_policies = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "AWS": "*"
      },
      "Action": "es:*",
      "Resource": "*"
    }
  ]
}
POLICY  

  encrypt_at_rest {
    enabled = true
  }

  cluster_config {
    instance_type  = "t3.small.elasticsearch"
    instance_count = 2
    warm_enabled   = false
  }

  ebs_options {
    ebs_enabled = true
    volume_type = "gp2"
    volume_size = 10
  }

  advanced_security_options {
    enabled                        = true
    internal_user_database_enabled = true
    master_user_options {
      master_user_name     = "superuser"
      master_user_password = module.es-password.password
    }
  }

}
