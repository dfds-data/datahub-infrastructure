// Set the cloud provider to AWS
provider "aws" {
  region = "eu-central-1"
}
locals {
  name = "datacatalogue"
  tags = {
    Name        = "datacatalogue"
    Environment = "prod"
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
module "security_group" {
  source  = "terraform-aws-modules/security-group/aws"
  version = "~> 3"

  name        = "${local.name}-database-security-group"
  description = "${local.name} backend security group"
  vpc_id      = aws_default_vpc.default.id

  # ingress
  ingress_with_cidr_blocks = [
    {
      rule        = "postgresql-tcp"
      cidr_blocks = "0.0.0.0/0"
    },
  ]
  tags = local.tags
}

// RDS

module "db" {
  source = "terraform-aws-modules/rds/aws"

  identifier = local.name

  create_db_option_group    = false
  create_db_parameter_group = true

  # All available versions: https://docs.aws.amazon.com/AmazonRDS/latest/UserGuide/CHAP_PostgreSQL.html#PostgreSQL.Concepts
  engine         = "postgres"
  engine_version = "13"
  family         = "postgres13" # DB parameter group
  instance_class = "db.t3.micro"

  allocated_storage = 20

  # NOTE: Do NOT use 'user' as the value for 'username' as it throws:
  # "Error creating DB Instance: InvalidParameterValue: MasterUsername
  # user cannot be used as it is a reserved word used by the engine"
  name                   = local.name
  username               = "superuser"
  create_random_password = true
  random_password_length = 32
  port                   = 5432
  publicly_accessible    = true

  vpc_security_group_ids = [module.security_group.this_security_group_id]

  maintenance_window = "Mon:00:00-Mon:03:00"
  backup_window      = "03:00-06:00"

  backup_retention_period = 10

  parameters = [
    {
      name  = "rds.force_ssl"
      value = 1
    }
  ]

  subnet_ids = [aws_default_subnet.default_az1.id, aws_default_subnet.default_az2.id]
  tags       = local.tags
}

resource "aws_ssm_parameter" "database_password" {
  name        = "/${local.name}/db_credentials"
  description = "Password for the backend database for ${local.name}"
  type        = "SecureString"
  value = jsonencode({
    "username" = module.db.this_db_instance_username
    "password" = module.db.this_db_instance_password
  })
  overwrite = true
}

// Elastic
