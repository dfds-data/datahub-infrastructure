# Usage

```
terraform init
terraform apply -var 'kubernetes_account_number=123456789'

kubectl -n <namespace> apply -f k8s/

helm repo add datahub https://helm.datahubproject.io/

helm install -n <namespace> datahub datahub/datahub --values values.yaml
```