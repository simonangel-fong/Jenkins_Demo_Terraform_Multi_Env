# Jenkins Demo: Terraform Multi-Environment Pipeline

A production-style CI/CD pipeline that provisions AWS VPC infrastructure across multiple environments using Terraform, Jenkins on Kubernetes, and automated security scanning.

---

## DevOps CI/CD Pipeline Design

- **Multi-environment promotion** — Sequential Dev → Test → Prod pipeline with isolated S3 remote state per environment
- **Production safety gate** — Manual approval step blocks Prod deploy until explicitly confirmed
- **Infrastructure as Code** — Terraform with reusable custom VPC module, variable validation, plan/apply separation

---

## Jenkins Best Practices on Kubernetes

- **Helm deployment** — Jenkins provisioned as K8s StatefulSet via Helm chart — no manual server setup
- **Configuration as Code (JCasC)** — Credentials, plugins, and system config declared in `values.yaml` — fully reproducible
- **Reusable Shared Library** — `terraformDeploy()` and `confirmVpc()` abstract pipeline logic into reusable functions
- **Kubernetes Pod Agents** — Build runs in ephemeral K8s pods with multiple containers (Terraform, AWS CLI, Trivy)

---

## Security & Secrets Management

- **Shift-left security** — Trivy IaC scan runs before `plan`/`apply` — misconfigurations caught in CI, not production
- **Secrets hygiene** — AWS keys, GitHub token, and email credentials stored in K8s Secrets → injected as Jenkins credentials — zero hardcoded secrets in pipeline code
