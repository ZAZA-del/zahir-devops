# Zahir DevOps — Architecture & What We Built

## Overview

Full-stack cloud-native deployment on AWS, managed entirely as code.
Every resource is created, updated, and destroyed by Terraform + GitHub Actions —
no manual console clicks required after initial bootstrap.

---

## Tech Stack

| Layer | Technology |
|-------|-----------|
| Backend API | Java Spring Boot 3.5 (Java 21) |
| Frontend | Angular 21 + nginx |
| Kubernetes | AWS EKS 1.30 — 2× t3.medium nodes |
| Logging | Elasticsearch 8.13 + Kibana 8.13 + Filebeat DaemonSet |
| Serverless | AWS Lambda (Python 3.13) + API Gateway |
| Container Registry | AWS ECR |
| CI/CD | GitHub Actions |
| Infrastructure as Code | Terraform (S3 remote state + DynamoDB locking) |

---

## What Terraform Manages (Full Infrastructure as Code)

Every AWS resource is managed by Terraform — destroy wipes everything,
apply recreates it from zero.

| File | Resources |
|------|-----------|
| `vpc.tf` | VPC (192.168.0.0/16), 4 subnets (2 public + 2 private), IGW, NAT Gateway, EIP, 3 route tables, 4 route table associations, 2 security groups (ControlPlane + ClusterShared) |
| `eks.tf` | EKS cluster (k8s 1.30), managed node group (2× t3.medium) |
| `addons.tf` | EKS add-ons: vpc-cni, kube-proxy, coredns |
| `iam.tf` | IAM roles for EKS cluster, EKS nodes, Lambda — all policy attachments |
| `ecr.tf` | ECR repos: zahir-backend, zahir-frontend (force_delete=true) |
| `lambda.tf` | Lambda function zahir-hello-proxy (Python 3.13), Lambda permission |
| `apigateway.tf` | REST API, root GET method, Lambda proxy integration, deployment, prod stage |
| `providers.tf` | AWS provider, S3 backend (state bucket + DynamoDB lock table) |
| `variables.tf` | All configuration variables |
| `outputs.tf` | Live app URLs, cluster info, ECR URIs |

**Terraform does NOT manage:**
- The S3 bucket and DynamoDB table for Terraform state (bootstrapped once manually)
- Kubernetes workload YAMLs (`k8s/`) — these are deployed by `kubectl apply` in CI

---

## Architecture Diagram

```
                     GitHub Actions CI/CD
          ┌──────────────────────────────────────────┐
          │ 1. Test (mvn verify + ng build)           │
          │ 2. Terraform plan → apply                 │
          │ 3. Docker build → ECR push                │
          │ 4. kubectl apply → EKS rollout            │
          │ 5. terraform apply -var URLs (outputs)    │
          └─────────────────┬────────────────────────┘
                            │
          ┌─────────────────▼────────────────────────┐
          │              AWS us-east-1                │
          │                                          │
          │  VPC 192.168.0.0/16                       │
          │  ┌────────────┐  ┌──────────────────────┐│
Internet──┼─►│ AWS ELBs   │  │  EKS Cluster (1.30)  ││
          │  │ (3×)       │─►│  Namespace: zahir     ││
          │  └────────────┘  │                      ││
          │                  │  zahir-backend (×2)  ││
          │  ┌────────────┐  │  Spring Boot 3.5     ││
          │  │ API Gateway│  │                      ││
          │  │ + Lambda   │─►│  zahir-frontend (×2) ││
          │  └────────────┘  │  Angular 21 + nginx  ││
          │                  │                      ││
          │  ECR             │  elasticsearch (×1)  ││
          │  zahir-backend   │  kibana (×1)         ││
          │  zahir-frontend  │  filebeat DaemonSet  ││
          │                  └──────────────────────┘│
          └──────────────────────────────────────────┘
```

---

## Kubernetes Workloads (`k8s/`)

Deployed via `kubectl apply` in CI — not managed by Terraform.

```
k8s/
├── namespace.yaml              # zahir namespace
├── backend/
│   └── deployment.yaml         # Deployment (2 replicas) + LoadBalancer Service
├── frontend/
│   └── deployment.yaml         # Deployment (2 replicas) + LoadBalancer Service
└── logging/
    ├── elasticsearch.yaml       # Deployment + ClusterIP Service
    ├── kibana.yaml              # Deployment + LoadBalancer Service
    └── filebeat.yaml            # DaemonSet + ConfigMap + RBAC
```

---

## Key Problems Solved

### 1. Angular blank page (Zone.js)
- **Root cause:** `polyfills: []` missing in angular.json — Zone.js not bundled
- **Fix:** `npm install zone.js --save` + `"polyfills": ["zone.js"]` in angular.json

### 2. nginx cache poisoning blank page
- **Root cause:** nginx `try_files $uri /index.html` served HTML as JS for missing asset hashes
- **Fix:** `try_files $uri =404` for static assets + `Cache-Control: no-cache` on index.html

### 3. EKS nodes NotReady after Terraform rebuild (NetworkPluginNotReady)
- **Root cause:** `bootstrap_self_managed_addons = false` — EKS doesn't auto-install CNI/kube-proxy/CoreDNS
- **Fix:** `addons.tf` — vpc-cni + kube-proxy install before node group, coredns after

### 4. SG `DependencyViolation` on destroy
- **Root cause:** `cluster_shared` SG has circular ingress rules with the EKS cluster SG; Terraform tried to delete SG while node ENIs still attached
- **Fix:** Staged destroy in workflow: drain namespace → target-destroy node group → sleep 60 → revoke circular SG rules → full destroy

### 5. Lambda broken after rebuild
- **Root cause:** Backend ELB hostname changes on every rebuild; was hardcoded
- **Fix:** Deploy job reads new hostname from kubectl, runs `terraform apply -var="backend_lb_url=http://..."` to update Lambda env and Terraform outputs

### 6. Bootstrap was needed once
- Run `bash infra/bootstrap.sh` once to create the S3 state bucket and DynamoDB lock table before first `terraform init`

---

## Remote State

| Resource | Name |
|----------|------|
| S3 bucket | `zahir-terraform-state-143575007958` |
| DynamoDB table | `zahir-terraform-locks` |
| State key | `zahir/terraform.tfstate` |
