# DFDS Data Catalogue (DataHub)

This repository holds the terraform code, terragrunt code and configuration for the
[DataHub helm-chart](https://github.com/acryldata/datahub-helm/) as used in DFDS.

## Terraform/Terragrunt

If starting from scratch, edit "remote_state.config.bucket" in
terraform/terragrunt/dev/terragrunt.hcl to be an unique value (S3 naming limitation). Otherwise
leave as-is.

```bash
cd terraform/terragrunt/dev
terragrunt init
terragrunt apply
```

You can retrieve the hostnames and passwords by running

```bash
terragrunt output -json
```

This is also what the CI/CD pipeline uses to pass the values on to the helm chart.

## DataHub configuration

### Infrastructure

We use mostly managed prerequisites, which includes

- An EKS cluster (org-wide)
- A kafka cluster (org-wide)
- AWS Elastic Search
- AWS RDS managed MySQL

The only self-managed service is Confluent Schema Registry, which runs in EKS.

See the [terraform code](./terraform) for more details. We don't use a graph database such as Neo4j.

### DataHub Configuration

Our configuration makes these alterations from the defaults:

- OIDC for authentication, which syncs with an LDAP directory in our organization
- Elastic Search instead of Neo4j for the graph search functionality
- Custom topic names and group ids for kafka, to abide by ACL authorization in kafka

## CI/CD

CI/CD is set up with Azure Pipelines, see [the pipeline definition](./azure-pipelines.yaml) for
details. Some configuration values, such as the k8s service connection and the kafka settings, must
be configured manually in Azure Pipelines.

The flow is roughly like this:

1. Upgrade infrastructure with terragrunt for the dev environment
2. If successful, get terraform output and replace in [secrets](./k8s/secret.yaml) and
   [values](values-compass.yaml).
3. Run `helm upgrade` against the k8s cluster
4. Repeat 1-3 for prod environment

## How to upgrade

0. Read the release notes of all versions between the current and the desired and see if there are
   breaking changes that must be taken into account. The DataHub Helm Chart release notes can be
   found [here](https://github.com/acryldata/datahub-helm/releases) and the DataHub release notes
   can be found [here](https://github.com/linkedin/datahub/releases).
1. Update the [dataHubHelmChartVersion](azure-pipelines.yml) to the desired version.
2. Update the [DataHub Helm Chart Values YAML file](datahub/values.yaml) with the corresponding
   versions of the different components.
3. Deploy.

## Note on UI-based ingestion

**This should be revisited when UI-based ingestion is implemented**

Starting from v0.8.26, UI-based ingestion is possible in DataHub. However, the feature is still
quite young and the documentation is scarce.

We have found, that the current accepted workaround for making the `datahub-actions` pod work, is
to:

- Manually specify the configurations for Kafka under `extraEnvs` for the container, without a
  `SPRING_` prefix (same configurations as GMS are needed)
- Find some way to change the Kafka topic names to our custom ones for this container too

These things are difficult right now, because the code has not been open sourced yet. Therefore, the
decision is made to hold off on implementing this until it is a bit more straight forward.
