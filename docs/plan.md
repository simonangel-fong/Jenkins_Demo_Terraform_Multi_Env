# Project Plan: Jenkins + Terraform Multi-Environment VPC Pipeline

## Goal

Demonstrate a production-style infrastructure CI/CD pipeline using Jenkins and Terraform, promoting changes across Dev → Test → Prod environments.

---

## Branch & Environment Map

```
Branch:       feature/vpc  →  master
Environment:  sandbox/dev  →  dev  →  test  →  prod
```

---

## Project Structure

```
project/
├── infra/
│   ├── modules/vpc/
│   │   ├── main.tf
│   │   ├── variables.tf
│   │   └── outputs.tf
│   ├── envs/
│   │   ├── dev/
│   │   │   ├── terraform.tfvars
│   │   │   └── backend.hcl
│   │   ├── test/
│   │   │   ├── terraform.tfvars
│   │   │   └── backend.hcl
│   │   └── prod/
│   │       ├── terraform.tfvars
│   │       └── backend.hcl
│   ├── main.tf
│   ├── variables.tf
│   └── providers.tf
├── cicd/
│   └── cd/
│       ├── Jenkinsfile
│       └── values.yaml
├── .gitignore
└── README.md
```

---

## Step 1 — Sandbox Development

**Goal:** Build and validate Terraform VPC module locally before any CI/CD integration.

**Steps:**

1. Create branch `feature/vpc`
2. Create VPC module under `infra/modules/vpc/`:
   - `main.tf`: VPC, subnets (public/private), IGW, route tables using `terraform-aws-modules/vpc/aws`
   - `variables.tf`: vpc_name, cidr, azs, public/private subnet CIDRs, environment tag
   - `outputs.tf`: vpc_id, subnet IDs
3. Create root config (`infra/main.tf`, `variables.tf`, `providers.tf`) calling the VPC module
4. Configure remote state per environment:
   - S3 bucket: `<project>-tfstate`
   - Key pattern: `<project>/<env>/terraform.tfstate`
   - Use S3 for state locking(terraform latest version)
   - `envs/dev/backend.hcl` referencing bucket/key/region
5. Create `envs/dev/terraform.tfvars` with dev-specific values (no hardcoded values in module)
6. Validate locally:
   ```bash
   terraform init -backend-config=envs/dev/backend.hcl
   terraform fmt -recursive
   terraform validate
   terraform plan -var-file=envs/dev/terraform.tfvars
   ```

**Done when:**

- [ ] `terraform validate` passes
- [ ] `terraform plan` runs cleanly for dev environment
- [ ] No hardcoded environment values in module or root config
- [ ] Remote state initialises successfully

---

## Step 2 — Configure Jenkins Instance

**Goal:** Deploy Jenkins on Kubernetes via Helm, ready to run pipeline jobs.

**Steps:**

1. Add Jenkins Helm chart config to `cicd/cd/values.yaml`:
   - Enable Kubernetes plugin for agent pods
   - Mount AWS credentials as a Kubernetes secret → Jenkins credential store
   - Install plugins: `git`, `pipeline`, `kubernetes`, `aws-credentials`, `terraform`
2. Deploy Jenkins:
   ```bash
   helm repo add jenkins https://charts.jenkins.io
   helm upgrade --install jenkins jenkins/jenkins -f cicd/cd/values.yaml -n jenkins
   ```
3. Configure Jenkins credentials:
   - AWS Access Key / Secret (type: AWS Credentials) — ID: `aws-creds`
   - GitHub token for SCM polling — ID: `github-token`
4. Install Terraform binary on Jenkins agent image (or use `hashicorp/terraform` container as agent)
5. Create two pipeline jobs pointing to `cicd/cd/Jenkinsfile`:
   - `feature-vpc-pr` — triggered on PR branches matching `feature/*`
   - `master-pipeline` — triggered on merge to `master`

**Done when:**

- [ ] Jenkins accessible and agents run in K8s pods
- [ ] AWS and GitHub credentials stored securely
- [ ] Both pipeline jobs created and can connect to repo

---

## Step 3 — Pipeline: `feature/vpc-pr`

**Goal:** Automated validation on every push to a feature branch; produces a plan for PR review.

**Trigger:** Push to `feature/*` branch (SCM polling or webhook)

**Jenkinsfile stages:**

```
Checkout → fmt → validate → plan (dev)
```

| Stage    | Command                                                                              |
| -------- | ------------------------------------------------------------------------------------ |
| Checkout | `git checkout`                                                                       |
| Format   | `terraform fmt -recursive -check` — fail if unformatted                              |
| Validate | `terraform validate`                                                                 |
| Plan     | `terraform plan -var-file=envs/dev/terraform.tfvars -out=tfplan.binary`              |
| Publish  | Archive `tfplan.binary` as build artifact; post plan output as PR comment (optional) |

> No `apply` on feature branches. Plan output serves as the PR diff.

**Done when:**

- [ ] Pipeline triggers automatically on feature branch push
- [ ] fmt failure blocks the pipeline
- [ ] Plan output visible in Jenkins console / PR

---

## Step 4 — Pipeline: `master-dev`

**Goal:** Auto-deploy to dev on every merge to master.

**Trigger:** Merge / push to `master` (automatic)

**Stages:**

```
Checkout → fmt → validate → plan (dev) → apply (dev) → confirm
```

| Stage    | Command                                                                                 |
| -------- | --------------------------------------------------------------------------------------- |
| fmt      | `terraform fmt -recursive -check`                                                       |
| validate | `terraform validate`                                                                    |
| plan     | `terraform plan -var-file=envs/dev/terraform.tfvars -out=tfplan`                        |
| apply    | `terraform apply tfplan`                                                                |
| confirm  | `aws ec2 describe-vpcs --filters Name=tag:Env,Values=dev` — fail pipeline if VPC absent |

**Done when:**

- [ ] Merge to master triggers deploy to dev automatically
- [ ] AWS CLI confirmation step validates real infrastructure exists
- [ ] State stored remotely in S3

---

## Step 5 — Pipeline: `master-test`

**Goal:** Promote dev infrastructure to test with a security scan gate.

**Trigger:** Manual (`Build Now` in Jenkins)

**Stages:**

```
Checkout → fmt → validate → Trivy scan → plan (test) → apply (test) → confirm
```

| Stage          | Command                                                                       |
| -------------- | ----------------------------------------------------------------------------- |
| fmt / validate | same as above                                                                 |
| Trivy scan     | `trivy config infra/` — scan IaC for misconfigurations; fail on HIGH/CRITICAL |
| plan           | `terraform plan -var-file=envs/test/terraform.tfvars -out=tfplan`             |
| apply          | `terraform apply tfplan`                                                      |
| confirm        | `aws ec2 describe-vpcs --filters Name=tag:Env,Values=test`                    |

> Trivy is the key addition over master-dev. Keeps the security gate lightweight for a demo.

**Done when:**

- [ ] Pipeline is manually triggered from Jenkins UI
- [ ] Trivy scan runs and blocks on findings (or passes cleanly)
- [ ] Test VPC confirmed via AWS CLI

---

## Step 6 — Pipeline: `master-prod`

**Goal:** Controlled promotion to production with a manual approval gate.

**Trigger:** Manual (`Build Now` in Jenkins)

**Stages:**

```
Checkout → fmt → validate → plan (prod) → [Manual Approval] → apply (prod) → confirm
```

| Stage          | Command                                                           |
| -------------- | ----------------------------------------------------------------- |
| fmt / validate | same as above                                                     |
| plan           | `terraform plan -var-file=envs/prod/terraform.tfvars -out=tfplan` |
| **Approval**   | `input` step — engineer reviews plan output before proceeding     |
| apply          | `terraform apply tfplan`                                          |
| confirm        | `aws ec2 describe-vpcs --filters Name=tag:Env,Values=prod`        |

> The `input` step is the critical prod safeguard. Times out and aborts if not approved within N minutes.

**Done when:**

- [ ] Pipeline pauses at approval step; apply only runs after explicit approval
- [ ] Prod VPC confirmed via AWS CLI
- [ ] State isolated in prod S3 key

---

## Notes

- **State isolation:** Each environment has its own `backend.hcl` and S3 key. Never share state files across environments.
- **Credentials:** AWS credentials injected via Jenkins credential store — never in code or tfvars.
- **Trivy:** Only required for test pipeline in this demo. In production, run on all environments.
- **Simplifications acceptable for demo:** single AWS account for all envs, shared S3 state bucket (different keys), no Sentinel/OPA policy enforcement.
- **`.gitignore`** must exclude: `.terraform/`, `*.tfstate`, `*.tfstate.backup`, `tfplan*`, `*.hcl` local overrides.
