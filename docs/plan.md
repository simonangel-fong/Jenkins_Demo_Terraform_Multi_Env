# Project: Jenkins Demo - Deploy Multiple-environment VPC vis Terraform

- [Project: Jenkins Demo - Deploy Multiple-environment VPC vis Terraform](#project-jenkins-demo---deploy-multiple-environment-vpc-vis-terraform)
  - [Goal](#goal)
  - [Branch and environment](#branch-and-environment)
  - [High-Level workFlow](#high-level-workflow)
  - [Project Structure](#project-structure)
  - [Step 1 — Terraform (Infrastructure Design)](#step-1--terraform-infrastructure-design)
  - [Step 2 — Jenkins Pipeline](#step-2--jenkins-pipeline)
  - [Step 3 — Security \& Governance](#step-3--security--governance)
  - [Step 4 — Promotion Strategy](#step-4--promotion-strategy)
  - [Step 5 — Validation Checklist](#step-5--validation-checklist)
  - [Step 6 — Key Metrics (KPIs)](#step-6--key-metrics-kpis)
  - [Optional Improvements (if time permits)](#optional-improvements-if-time-permits)
  - [Notes](#notes)

## Goal

Build a production-style infrastructure pipeline to demonstrate:

- Jenkins pipeline design for infrastructure
- Terraform modular architecture
- Multi-environment promotion (Dev → Test → Prod)
- Infrastructure security and governance practices

> Scope: Infrastructure CI/CD (includes controlled promotion, not application deployment)

---

## Branch and environment

```txt
Environment: |       dev       |  dev  |  test  |  prod  |
Branch:      ----- master --------------------------
                \_feature/vpc_/
```

## High-Level workFlow

- workFlow: feature/vpc-pr

```txt
Git push → Jenkins pipeline triggered
→ terraform fmt
→ terraform validate
→ terraform plan
→ PR
```

- workFlow: master-dev

```txt
merge master → Jenkins pipeline triggered
→ terraform fmt
→ terraform validate
→ terraform plan
→ terraform apply
→ aws cli confirm
```

- workFlow: master-test

```txt
Manual triggered Jenkins pipeline
→ terraform fmt
→ terraform validate
→ trivy scan
→ terraform plan
→ terraform apply
→ aws cli confirm
```

- workFlow: master-prod

```txt
Manual triggered Jenkins pipeline
→ terraform fmt
→ terraform validate
→ terraform plan
→ terraform apply
→ aws cli confirm
```

---

## Project Structure

```txt
project/
├── infra/
│ ├── modules/
│ ├── envs/
│ │ └── dev/                    # dev env
│ │    ├── terraform.tfvars
│ │    └── backend.hcl          # beckend S3
│ │ └── test/                   # test env
│ │ └── prod/                   # prod env
│ ├── variables.tf
│ ├── providers.tf
│ └── main.tf
│
├── cicd/
│ └── cd/
│     ├── Jenkinsfile
│     └── values.yaml       # Jenkins instance config
├── README.md
└── .gitignore
```

---

## Step 1 — Terraform (Infrastructure Design)

Goal: create feature branch and sandbox development

- create a new branch `feature/vpc`
- initialize terraform project
  - configure remote state:
    - backend config: `env/sandbox/backend.htl`
    - S3 bucket for state storage
    - structure:
      ```
      <project_name>/<env>/terraform.tfstate
      ```
- develop feature in sandbox
  - `variables.tf`: define variables and defaut values
  - `env/sandbox/terraform.tfvars`: dev environment-specific values
  - reference reusable modules: `terraform-aws-modules`

Done when:

- feature/vpc creates
- remote state configures
- `terraform validate` passes
- `terraform plan` works for each environment
- no hardcoded environment values

---

## Step 2 — Jenkins Pipeline

Goal: implement infrastructure CI/CD pipeline

Stages:

```txt
Checkout → Validate → Security Scan → Plan → Apply (Dev) → Approval → Apply (Prod) → Verify → Post
```

1. **Checkout**

2. **Validate**
   - `terraform fmt`
   - `terraform validate`

3. **Security Scan**
   - run `tfsec` or `trivy`
   - fail pipeline if:
     - open security groups
     - insecure CIDR ranges

4. **Plan (Dev)**

5. **Apply (Dev)**
   - automatic deployment

6. **Approval Gate**
   - manual approval before production

7. **Apply (Prod)**
   - only after approval
   - only from `master` branch

8. **Verification**
   - simple validation script:
     - check VPC resources exist
     - test connectivity (ping / curl inside VPC)

9. **Post**
   - archive logs
   - cleanup temp files

Done when:

- Dev environment deploys automatically
- Prod requires manual approval
- pipeline runs end-to-end successfully

---

## Step 3 — Security & Governance

Goal: enforce production-grade practices

- store AWS credentials in Jenkins securely
  - use IAM roles or secrets manager
- no credentials in code or Terraform files
- enforce branch rules:
  - only `master` branch can trigger production deploy

- implement RBAC in Jenkins:
  - only authorized users can approve production stage

Done when:

- unauthorized users cannot deploy to prod
- secrets are not exposed in logs or code

---

## Step 4 — Promotion Strategy

Goal: ensure controlled and consistent environment promotion

- use **single Jenkinsfile (Single Source of Truth)**
- same Terraform code for all environments
- only `.tfvars` differ per environment

Promotion flow:

```txt
Dev success → manual approval → Prod deployment
```

Done when:

- no duplicated pipeline logic
- environments differ only by configuration

---

## Step 5 — Validation Checklist

Before calling it done:

- [ ] terraform validate runs in pipeline
- [ ] security scan blocks insecure configs
- [ ] Dev environment auto-deploys
- [ ] Prod requires manual approval
- [ ] remote state configured
- [ ] no hardcoded credentials
- [ ] pipeline logs clearly show promotion flow

---

## Step 6 — Key Metrics (KPIs)

| Metric               | Target Goal                              |
| -------------------- | ---------------------------------------- |
| Deployment Speed     | < 5 minutes for Dev provisioning         |
| Configuration Drift  | 0% (single pipeline + Terraform state)   |
| Recovery Time (MTTR) | < 10 minutes (recreate via state + code) |

---

## Optional Improvements (if time permits)

Keep practical and interview-relevant:

- add `terraform plan` diff visualization
- add retry/timeout for apply stage
- integrate cost estimation (Infracost)
- add Slack/Email notification for approvals
- add drift detection job (scheduled pipeline)

---

## Notes

- focus on **clarity of promotion pipeline**
- highlight **Dev → Prod control and governance**
- avoid over-engineering (no need for full platform setup)
- emphasize:
  - security scanning
  - approval gates
  - immutable infrastructure mindset

---
