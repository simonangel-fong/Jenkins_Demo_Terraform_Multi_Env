# Project Plan: Jenkins + Terraform Multi-Environment VPC Pipeline

[Back](../README.md)

- [Project Plan: Jenkins + Terraform Multi-Environment VPC Pipeline](#project-plan-jenkins--terraform-multi-environment-vpc-pipeline)
  - [Goal](#goal)
  - [Project Structure](#project-structure)
  - [Infrastructure: Custom VPC Module](#infrastructure-custom-vpc-module)
  - [Jenkins on Kubernetes](#jenkins-on-kubernetes)
  - [Pipeline: `Jenkinsfile`](#pipeline-jenkinsfile)
  - [Shared Library: `terraformDeploy()`](#shared-library-terraformdeploy)
  - [Shared Library: `confirmVpc()`](#shared-library-confirmvpc)

---

## Goal

Demo a production-style infrastructure CI/CD pipeline using Jenkins on Kubernetes and Terraform, promoting a custom VPC across Dev → Test → Prod with security scanning and a manual approval gate.

---

## Project Structure

```
Jenkins_Demo_Terraform_Multi_Env/
├── Jenkinsfile                    # Master pipeline (Dev → Test → Approve → Prod)
├── vars/
│   ├── terraformDeploy.groovy     # Shared library: fmt → init → validate → scan → plan → apply
│   └── confirmVpc.groovy          # Shared library: post-apply VPC validation via AWS CLI
├── infra/
│   ├── 01_variables.tf            # Root variables (project, env, region, CIDR)
│   ├── 02_providers.tf            # AWS provider ~>6.0, S3 remote backend
│   ├── 03_main.tf                 # Calls vpc module
│   ├── env/
│   │   ├── sandbox/               # Local dev (terraform.tfvars, backend.hcl)
│   │   ├── dev/                   # (terraform.tfvars, backend.hcl)
│   │   ├── test/                  # (terraform.tfvars, backend.hcl)
│   │   └── prod/                  # (terraform.tfvars.example, backend.hcl.example)
│   └── modules/vpc/
│       ├── vpc.tf                 # VPC, IGW, subnets, route tables, NAT Gateway
│       ├── vpc_log.tf             # VPC Flow Logs, CloudWatch, KMS CMK
│       ├── variables.tf
│       └── outputs.tf
├── jenkins/
│   └── values.yaml                # Helm chart values: JCasC, plugins, K8s secret injection
└── docs/
    └── plan.md
```

---

## Infrastructure: Custom VPC Module

Located at `infra/modules/vpc/`. Called once from `infra/03_main.tf` with per-environment variables.

**Resources provisioned:**

- VPC with DNS support and hostnames enabled
- Internet Gateway
- 2x Public subnets (one per AZ) + Public route table → IGW
- 2x Private subnets (one per AZ) + Private route table → NAT Gateway
- NAT Gateway with Elastic IP (in first AZ public subnet)
- VPC Flow Logs → CloudWatch Logs (7-day retention)
- KMS CMK for Flow Logs encryption (key rotation enabled)
- IAM role for VPC Flow Logs service

**Network layout (ca-central-1):**

```
VPC: 10.0.0.0/16
├── ca-central-1a  public: 10.0.101.0/24  private: 10.0.1.0/24
└── ca-central-1b  public: 10.0.102.0/24  private: 10.0.2.0/24
```

**Remote state:** S3 backend per environment, key pattern `jenkins-terraform/<env>/terraform.tfstate`, encryption enabled.

**Default tags** applied to all resources: `Project`, `Environment`, `ManagedBy=terraform`.

---

## Jenkins on Kubernetes

Jenkins is deployed via Helm into a Kubernetes cluster. No manual server configuration.

**Helm + JCasC (`jenkins/values.yaml`):**

- Credentials (AWS, GitHub, Gmail, S3 bucket name) sourced from K8s Secrets at deploy time
- Plugins declared and auto-installed: `kubernetes`, `workflow-aggregator`, `git`, `configuration-as-code`, `aws-credentials`, `email-ext`, and others
- Controller runs zero executors — all work runs in ephemeral K8s pod agents

**K8s Secrets → Jenkins credentials mapping:**

| K8s Secret key                                | Jenkins Credential ID | Used for               |
| --------------------------------------------- | --------------------- | ---------------------- |
| `aws-access-key-id` / `aws-secret-access-key` | `aws-creds`           | Terraform AWS auth     |
| `tf-state-bucket`                             | `tf-state-bucket`     | S3 backend bucket name |
| `github-token`                                | `github-token`        | SCM checkout           |
| `mail-smtp-*`                                 | `gmail_cred`          | Pipeline notifications |

---

## Pipeline: `Jenkinsfile`

**Agent:** Kubernetes pod (label: `agent-terraform`, default container: `terraform`)

**Options:** timestamps, no concurrent builds, keep 20 builds

**Trigger:** SCM poll every 2 hours (`H/2 * * * *`)

**Stages:**

```
Deploy Dev → Deploy Test → Approve Prod → Deploy Prod
```

Each Deploy stage calls two shared library functions:

1. `terraformDeploy(env, tfDir, awsRegion, stateBucketCredId)`
2. `confirmVpc(env, awsRegion)`

**Post actions:**

| Result  | Action                                               |
| ------- | ---------------------------------------------------- |
| Success | Email: all environments deployed                     |
| Failure | Email: failed stage name + last 100 log lines        |
| Aborted | Email: production approval was rejected or timed out |

---

## Shared Library: `terraformDeploy()`

Defined in `vars/terraformDeploy.groovy`. Runs six stages per environment:

| Stage    | Container   | Command                                                                     |
| -------- | ----------- | --------------------------------------------------------------------------- |
| Fmt      | `terraform` | `terraform fmt -recursive -check`                                           |
| Init     | `terraform` | `terraform init -backend-config=bucket/key/region -reconfigure`             |
| Validate | `terraform` | `terraform validate`                                                        |
| Scan     | `trivy`     | `trivy config infra`                                                        |
| Plan     | `terraform` | `terraform plan -var="env=<ENV>" -out=tfplan` + archive tfplan + tfplan.txt |
| Apply    | `terraform` | `terraform apply -auto-approve tfplan`                                      |

Plugin cache (`TF_PLUGIN_CACHE_DIR=/terraform-cache`) set during Init to speed up subsequent environments.

---

## Shared Library: `confirmVpc()`

Defined in `vars/confirmVpc.groovy`. Runs one stage per environment after Apply:

| Stage       | Container | What it does                                                                                             |
| ----------- | --------- | -------------------------------------------------------------------------------------------------------- |
| Confirm VPC | `aws`     | `aws ec2 describe-vpcs` filtered by tags `Project`, `Environment`, `ManagedBy` — errors if VPC not found |

This acts as a post-deploy smoke test confirming the resource actually exists in AWS.
