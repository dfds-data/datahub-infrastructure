output "es_host" {
  value = aws_elasticsearch_domain.datahub-es.endpoint
}

output "es_password" {
  value = module.es-password.password
  sensitive = true
}

output "db_host" {
  value = module.db.db_instance_address
}

output "db_port" {
  value = module.db.db_instance_port
}

output "db_username" {
  value = module.db.db_instance_username
  sensitive = true
}

output "db_password" {
  value = module.db.db_instance_password
  sensitive = true
}