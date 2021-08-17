resource "random_password" "password" {
  length           = 32
  special          = true
  number           = true
  lower            = true
  upper            = true
  override_special = "!_.-=*"
}

resource "aws_ssm_parameter" "secret_password" {
  name  = var.ssm_path
  type  = "SecureString"
  value = random_password.password.result
}
