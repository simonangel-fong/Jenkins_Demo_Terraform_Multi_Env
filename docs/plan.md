# Project Plan: Jenkins + Terraform Multi-Environment VPC Pipeline

## Goal

Demo a production-style infrastructure CI/CD pipeline using Jenkins and Terraform, promoting a VPC across Dev → Test → Prod.

---

## Branch & Environment Map

```
feature/vpc  →  master
sandbox/dev  →  dev  →  test  →  prod
```

---

## Project Structure

```
project/
├── docs/plan.md
├── infra/
│   ├── modules/vpc/
│   │   ├── vpc.tf
│   │   ├── variables.tf
│   │   └── outputs.tf
│   ├── env/
│   │   ├── dev/      (terraform.tfvars, backend.hcl)
│   │   ├── test/     (terraform.tfvars, backend.hcl)
│   │   └── prod/     (terraform.tfvars, backend.hcl)
│   ├── 01_variables.tf
│   ├── 02_providers.tf
│   └── 03_main.tf
├── jenkins/
│   ├── script/
│   │   ├── deploy.sh  (fmt → init → validate → scan → plan → archive → apply)
│   │   └── test.sh    (aws ec2 describe-vpcs filtered by Environment tag)
│   └── values.yaml    (Jenkins Helm config)
└── Jenkinsfile        (master pipeline: dev→test→prod)
```

---

## Step 1 — Sandbox Development

Build and validate the Terraform VPC module locally.

- VPC module under `infra/modules/vpc/` using `terraform-aws-modules/vpc/aws`
- Root config (`01_variables.tf`, `02_providers.tf`, `03_main.tf`) calls the module
- Remote state: S3 bucket per env, key pattern `<project>/<env>/terraform.tfstate`, S3 locking
- Per-env config in `infra/env/<env>/` — no hardcoded values in module

**Done when:**

- [x] `terraform validate` passes
- [x] `terraform plan` runs cleanly for dev
- [x] No hardcoded environment values in module or root config
- [x] Remote state initialises successfully

---

## Step 2 — Configure Jenkins

Deploy Jenkins on Kubernetes via Helm, ready to run pipeline jobs.

- `cicd/jenkins/values.yaml`: Kubernetes plugin, AWS credentials as K8s secret, plugins: `git`, `pipeline`, `kubernetes`, `aws-credentials`, `terraform`
- Deploy: `helm upgrade --install jenkins jenkins/jenkins -f cicd/jenkins/values.yaml -n jenkins`
- Jenkins credentials: AWS keys (ID: `aws-creds`), S3 bucket name (ID: `tf-state-bucket`), GitHub token (ID: `github-token`)
- Two pipeline jobs:
  - `feature-vpc-pr` — triggers on `feature/*`, uses `Jenkinsfile.pr`
  - `master-pipeline` — triggers on merge to `master`, uses `Jenkinsfile`

**Done when:**

- [x] Jenkins accessible, agents run in K8s pods
- [x] AWS and GitHub credentials stored securely
- [x] Both pipeline jobs created and connected to repo

---

## Step 3 — Master Pipeline (`Jenkinsfile`) — merge to master

```
checkout
→ dev deploy 
→ test deploy 
→ prod deploy (requires manual approval gate)
```

---

**Deploy module**

Stages
1. Dev stage:
   - `terraform fmt`(container terraform)
   - `terraform init`(container terraform)
   - `terraform validate`(container terraform)
   - `trivy config`(container trivy)
   - `terraform plan`(container terraform)
     - post: archive
   - `terraform apply`(container terraform)
   - `aws ec2 describe-vpcs`(container aws)
2. Test stage:
   - `terraform fmt`(container terraform)
   - `terraform init`(container terraform)
   - `terraform validate`(container terraform)
   - `trivy config`(container trivy)
   - `terraform plan`(container terraform)
     - post: archive
   - `terraform apply`(container terraform)
   - `aws ec2 describe-vpcs`(container aws)
3. Prod stage:
   - Manual Approval
   - `terraform fmt`(container terraform)
   - `terraform init`(container terraform)
   - `terraform validate`(container terraform)
   - `trivy config`(container trivy)
   - `terraform plan`(container terraform)
     - post: archive
   - `terraform apply`(container terraform)
   - `aws ec2 describe-vpcs`(container aws)
4. Always:
   - Send notification email

```txt
fmt → init → validate → trivy-scan → plan → archive → apply
```

| Step     | Command                                               |
| -------- | ----------------------------------------------------- |
| fmt      | `terraform fmt -recursive -check`                     |
| validate | `terraform validate`                                  |
| scan     | `trivy config --severity HIGH,CRITICAL --exit-code 1` |
| plan     | `terraform plan -var="env=<ENV>" -out=tfplan.binary`  |
| archive  | `archiveArtifacts tfplan.binary + tfplan.txt`         |
| apply    | `terraform apply tfplan.binary`                       |

---

**Test module**:

- jenkins\script\test.sh
- run `aws ec2 describe-vpcs` to simulate the testing
  - filtered by `Environment` tag to confirm the VPC exists.

**Done when:**
