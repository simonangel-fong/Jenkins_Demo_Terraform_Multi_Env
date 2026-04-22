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
├── infra/
│   ├── modules/vpc/
│   │   ├── vpc.tf
│   │   ├── variables.tf
│   │   └── outputs.tf
│   ├── env/
│   │   ├── dev/    (terraform.tfvars, backend.hcl)
│   │   ├── test/   (terraform.tfvars, backend.hcl)
│   │   └── prod/   (terraform.tfvars, backend.hcl)
│   ├── 01_variables.tf
│   ├── 02_providers.tf
│   └── 03_main.tf
├── cicd/jenkins/
│   ├── Jenkinsfile       (master pipeline: dev→test→prod)
│   └── values.yaml       (Jenkins Helm config)
└── docs/plan.md
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

## Step 3 — Pipeline

### PR Pipeline (`Jenkinsfile.pr`) — feature/\* branches

```
branch-guard → checkout → fmt → init → validate → plan → archive
```

Validates the change is safe before merge. Plan is archived for review.

### Master Pipeline (`Jenkinsfile`) — merge to master

```
checkout → fmt → init → validate → trivy-scan → plan → archive → apply
  (repeat per env: dev → test → prod)
  prod requires manual approval gate
```

**Deploy steps per environment:**

| Step     | Command                                               |
| -------- | ----------------------------------------------------- |
| fmt      | `terraform fmt -recursive -check`                     |
| validate | `terraform validate`                                  |
| scan     | `trivy config --severity HIGH,CRITICAL --exit-code 1` |
| plan     | `terraform plan -var="env=<ENV>" -out=tfplan.binary`  |
| archive  | `archiveArtifacts tfplan.binary + tfplan.txt`         |
| apply    | `terraform apply tfplan.binary`                       |

**Test/Confirm:** After each apply, run `aws ec2 describe-vpcs` filtered by `Environment` tag to confirm the VPC exists.

**Prod gate:** `input` step requiring manual approval before plan/apply.

**Done when:**

- [ ] PR pipeline runs on `feature/vpc` — fmt, validate, plan all pass
- [ ] Master pipeline promotes dev → test automatically
- [ ] Prod stage pauses for approval, then applies cleanly
- [ ] AWS confirm step verifies VPC tag in each environment
