variable "kubernetes_account_number" {
  type       = string
  description = "The account number of the k8s cluster"
}

variable "es_username" {
  type = string
  description = "Username for Elasticsearch master user"
}

variable "es_password" {
  type = string
  description = "Password for Elasticsearch master user"
}