# Learning project for Terraform + GCP

Just a learning project for myself to use both Terraform and GCP.
CI/CD will be done using Github Actions.

## Requirement

- Setup Google CLoud CLI - [https://docs.cloud.google.com/sdk/docs/install-sdk](https://docs.cloud.google.com/sdk/docs/install-sdk)
- Install Terraform CLI - [https://developer.hashicorp.com/terraform/install](https://developer.hashicorp.com/terraform/install)
- A GCP Project - [Create a GCP Project with this link](https://console.cloud.google.com/projectcreate)
- Google Compute Engine enabled on the project - [Click here to enable](https://console.developers.google.com/apis/library/compute.googleapis.com)

## Setup

To setup the project:
- Define the `terraform.tfvars` file. You can use the `terraform.tfvars.example` file provided in this repository and update with your own values.
- Run the `terraform init` cmd.
- Run the `terraform apply` cmd to run the project.

```shell
cp terraform.tfvars.example terraform.tfvars
terraform init
terraform apply
```
