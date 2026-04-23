# Diagram Prompt

this diagram shows my project that manage Terraform environment promotion in Jenkins.

## key components

- **Secrets hygiene**:
  - AWS keys, GitHub token, and email credentials stored in K8s Secrets → injected as Jenkins credentials — zero hardcoded secrets in pipeline code

## Draft

```txt
Zero Hardcoded Secrets

+------------------+     +-------------------+     +----------------------+
|   K8s Secrets    | --> |  Jenkins Pod Env  | --> | Jenkins Credentials  |
|                  |     |                   |     |                      |
| - AWS keys       |     |  (mounted at      |     | - AWS keys           |
| - GitHub token   |     |   pod startup)    |     | - GitHub token       |
| - Email creds    |     |                   |     | - Email creds        |
+------------------+     +-------------------+     +----------------------+
                                                              |
                                                             used by
                                                              |
                                                    +--------------------+
                                                    |  Pipeline Code     |
                                                    |  (no secrets)      |
                                                    +--------------------+
```
