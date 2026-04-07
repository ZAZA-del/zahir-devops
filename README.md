# Zahir DevOps — Academic Compliant Cloud Project

Full-stack cloud-native deployment meeting academic requirements:
**Java Spring Boot + Angular + Kubernetes (EKS) + Elasticsearch + Kibana + AWS Lambda + Terraform IaC + GitHub Actions CI/CD**

---

## Live URLs

| Service | URL |
|---------|-----|
| **Frontend (Angular)** | http://a6399fc5dbe4b477f95cba91561a8ee4-486874822.us-east-1.elb.amazonaws.com |
| **Backend API (Spring Boot)** | http://a7d1837a5e5b64a2a8b1af2c8061f58c-1613418956.us-east-1.elb.amazonaws.com |
| **Backend /hello** | http://a7d1837a5e5b64a2a8b1af2c8061f58c-1613418956.us-east-1.elb.amazonaws.com/hello |
| **Kibana** | http://a559a8fcbad304edba1b6a467118b587-708286872.us-east-1.elb.amazonaws.com:5601 |
| **Lambda (serverless)** | https://q9gzox7h34.execute-api.us-east-1.amazonaws.com/prod/ |
| **GitHub Repository** | https://github.com/ZAZA-del/zahir-devops |

---

## Verification Steps

Run these to confirm end-to-end:

```bash
# 1. Backend root
curl http://a7d1837a5e5b64a2a8b1af2c8061f58c-1613418956.us-east-1.elb.amazonaws.com/
# → "Backend is running"

# 2. Backend /hello
curl http://a7d1837a5e5b64a2a8b1af2c8061f58c-1613418956.us-east-1.elb.amazonaws.com/hello
# → "Hello World"

# 3. Frontend serves Angular (no-cache index.html)
curl -I http://a6399fc5dbe4b477f95cba91561a8ee4-486874822.us-east-1.elb.amazonaws.com/
# → Cache-Control: no-cache, no-store, must-revalidate

# 4. Frontend → Backend proxy (nginx → Spring Boot)
curl http://a6399fc5dbe4b477f95cba91561a8ee4-486874822.us-east-1.elb.amazonaws.com/api/hello
# → "Hello World"

# 5. Serverless Lambda (calls backend internally)
curl https://q9gzox7h34.execute-api.us-east-1.amazonaws.com/prod/
# → {"source":"AWS Lambda (serverless)","backend_response":"Hello World","message":"Lambda → Spring Boot: Hello World"}

# 6. Kibana
curl -s http://a559a8fcbad304edba1b6a467118b587-708286872.us-east-1.elb.amazonaws.com:5601/api/status | python3 -c "import sys,json; d=json.load(sys.stdin); print(d['name'])"
```

---

## Architecture

```
                        GitHub Actions CI/CD
                        ┌───────────────────────────────────┐
                        │ 1. mvn build + ng build            │
                        │ 2. docker buildx push → ECR        │
                        │ 3. kubectl apply → EKS             │
                        └──────────────┬────────────────────┘
                                       │
                ┌──────────────────────▼─────────────────────────┐
                │              AWS us-east-1                       │
                │                                                  │
                │  ┌────────────┐     ┌────────────────────────┐  │
Internet ──────►│  │ AWS ELB    │────►│   EKS Cluster          │  │
                │  │(3 LBs)     │     │   (Kubernetes 1.30)    │  │
                │  └────────────┘     │                        │  │
                │                     │  Namespace: zahir       │  │
                │  ┌──────────────┐   │                        │  │
                │  │ API Gateway  │   │  ┌──────────────────┐  │  │
                │  │ + Lambda     │   │  │ zahir-backend     │  │  │
                │  │ (serverless) │   │  │ Spring Boot 3.5   │  │  │
                │  └──────┬───────┘   │  │ 2 replicas        │  │  │
                │         │           │  └──────────────────┘  │  │
                │         └───────────┼──► /hello              │  │
                │                     │                        │  │
                │                     │  ┌──────────────────┐  │  │
                │                     │  │ zahir-frontend    │  │  │
                │                     │  │ Angular 21+nginx  │  │  │
                │                     │  │ 2 replicas        │  │  │
                │                     │  └──────────────────┘  │  │
                │                     │                        │  │
                │                     │  ┌──────────────────┐  │  │
                │                     │  │ elasticsearch     │  │  │
                │                     │  │ v8.13.0          │  │  │
                │                     │  └──────────────────┘  │  │
                │                     │                        │  │
                │                     │  ┌──────────────────┐  │  │
                │                     │  │ kibana            │  │  │
                │                     │  │ v8.13.0          │  │  │
                │                     │  └──────────────────┘  │  │
                │                     │                        │  │
                │                     │  ┌──────────────────┐  │  │
                │  ECR                │  │ filebeat          │  │  │
                │  zahir-backend      │  │ DaemonSet (2)     │  │  │
                │  zahir-frontend     │  │ → Elasticsearch  │  │  │
                │                     │  └──────────────────┘  │  │
                │                     └────────────────────────┘  │
                └──────────────────────────────────────────────────┘
```

---

## Tech Stack

| Requirement | Implementation |
|-------------|---------------|
| Backend | Java Spring Boot 3.5 (Java 21) |
| Frontend | Angular 21 |
| Kubernetes | AWS EKS 1.30 (2× t3.medium) |
| Logging | Elasticsearch 8.13 + Kibana 8.13 |
| Log shipping | Filebeat DaemonSet |
| Serverless | AWS Lambda + API Gateway |
| Container Registry | AWS ECR |
| CI/CD | GitHub Actions |

---

## Backend API

Spring Boot app with these endpoints:

```
GET /         → "Backend is running"
GET /hello    → "Hello World"
GET /health   → {"status":"UP"}
GET /api/info → JSON stack info
GET /actuator/* → Spring Actuator endpoints
```

---

## Serverless Component

An AWS Lambda function (`zahir-hello-proxy`) is deployed behind API Gateway:

- **Trigger**: HTTP GET via API Gateway
- **Runtime**: Python 3.13
- **Function**: Calls the Spring Boot backend `/hello` endpoint
- **URL**: `https://q9gzox7h34.execute-api.us-east-1.amazonaws.com/prod/`
- **Response**: `{"source": "AWS Lambda (serverless)", "backend_response": "Hello World", "message": "Lambda → Spring Boot: Hello World"}`

This demonstrates the serverless→container integration: public request → API Gateway → Lambda → EKS Spring Boot.

Source code: [`lambda/hello_proxy.py`](./lambda/hello_proxy.py)

---

## How to Run Locally

### Prerequisites
- Docker & Docker Compose
- Java 21 + Maven
- Node.js 22 + Angular CLI

### Local Development

```bash
git clone https://github.com/ZAZA-del/zahir-devops.git
cd zahir-devops

# Start everything (Spring Boot + Angular + Elasticsearch + Kibana)
docker-compose up --build

# Services:
# Backend:       http://localhost:8080
# Frontend:      http://localhost:80
# Elasticsearch: http://localhost:9200
# Kibana:        http://localhost:5601
```

### Run without Docker

```bash
# Backend
cd backend
./mvnw spring-boot:run
# → http://localhost:8080

# Frontend
cd frontend
npm install
ng serve
# → http://localhost:4200
```

---

## Kubernetes Deployment

### Structure

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

### Manual Deploy

```bash
# Configure kubectl
aws eks update-kubeconfig --region us-east-1 --name zahir-cluster

# Deploy
kubectl apply -f k8s/namespace.yaml
kubectl apply -f k8s/backend/
kubectl apply -f k8s/frontend/
kubectl apply -f k8s/logging/

# Check status
kubectl get all -n zahir
```

---

## CI/CD Pipeline

### On pull request (plan only — no apply, no destroy)

```
test-backend  ─┐
               ├─► terraform-plan   (init → validate → plan → post to PR comment)
test-frontend ─┘
```

### On push to main (auto apply)

```
test-backend  ─┐
               ├─► terraform-plan ──► terraform-apply   (apply -auto-approve)
test-frontend ─┤
               └─► build-and-push ──► deploy to EKS    (kubectl apply + rollout)
```

Terraform and the k8s deploy run in parallel after tests pass.
Terraform manages infrastructure; kubectl manages workloads.

### Pipeline file

`.github/workflows/ci-cd.yml`

---

## Terraform Infrastructure

Terraform is the source of truth for all AWS infrastructure.

### What Terraform manages

| Resource | Terraform file |
|----------|----------------|
| VPC, subnets, IGW, NAT, route tables | `infra/terraform/vpc.tf` |
| EKS cluster (`zahir-cluster`) | `infra/terraform/eks.tf` |
| EKS node group (`zahir-nodes`, 2× t3.medium) | `infra/terraform/eks.tf` |
| IAM roles (EKS cluster, node group, Lambda) | `infra/terraform/iam.tf` |
| ECR repos (`zahir-backend`, `zahir-frontend`) | `infra/terraform/ecr.tf` |
| Lambda function (`zahir-hello-proxy`) | `infra/terraform/lambda.tf` |
| API Gateway (`zahir-lambda-api`) | `infra/terraform/apigateway.tf` |

### Step 1 — Bootstrap remote state (one time only)

Run this **once** before the first `terraform init`:

```bash
bash infra/bootstrap.sh
```

This creates:
- S3 bucket `zahir-terraform-state-143575007958` (versioned, encrypted)
- DynamoDB table `zahir-terraform-locks` (for state locking)

### Step 2 — Import existing resources (one time only)

Because all AWS resources were created manually before Terraform was added,
run these imports **once** to bring them under Terraform management.

```bash
cd infra/terraform
terraform init

# IAM roles
terraform import aws_iam_role.eks_cluster \
  eksctl-zahir-cluster-cluster-ServiceRole-Ihp1DCeusPbU

terraform import aws_iam_role.eks_node \
  eksctl-zahir-cluster-nodegroup-zah-NodeInstanceRole-NILYKChlXvKS

terraform import aws_iam_role.lambda zahir-lambda-role

# IAM policy attachments
terraform import \
  aws_iam_role_policy_attachment.eks_cluster_policy \
  "eksctl-zahir-cluster-cluster-ServiceRole-Ihp1DCeusPbU/arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"

terraform import \
  aws_iam_role_policy_attachment.eks_vpc_controller \
  "eksctl-zahir-cluster-cluster-ServiceRole-Ihp1DCeusPbU/arn:aws:iam::aws:policy/AmazonEKSVPCResourceController"

terraform import \
  aws_iam_role_policy_attachment.eks_worker_node \
  "eksctl-zahir-cluster-nodegroup-zah-NodeInstanceRole-NILYKChlXvKS/arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"

terraform import \
  aws_iam_role_policy_attachment.eks_cni \
  "eksctl-zahir-cluster-nodegroup-zah-NodeInstanceRole-NILYKChlXvKS/arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"

terraform import \
  aws_iam_role_policy_attachment.eks_ecr_readonly \
  "eksctl-zahir-cluster-nodegroup-zah-NodeInstanceRole-NILYKChlXvKS/arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"

terraform import \
  aws_iam_role_policy_attachment.eks_ecr_pull_only \
  "eksctl-zahir-cluster-nodegroup-zah-NodeInstanceRole-NILYKChlXvKS/arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryPullOnly"

terraform import \
  aws_iam_role_policy_attachment.eks_ssm \
  "eksctl-zahir-cluster-nodegroup-zah-NodeInstanceRole-NILYKChlXvKS/arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"

terraform import \
  aws_iam_role_policy_attachment.lambda_basic \
  "zahir-lambda-role/arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"

# EKS cluster and node group
terraform import aws_eks_cluster.main zahir-cluster
terraform import aws_eks_node_group.main zahir-cluster:zahir-nodes

# ECR repositories
terraform import aws_ecr_repository.backend zahir-backend
terraform import aws_ecr_repository.frontend zahir-frontend

# Lambda
terraform import aws_lambda_function.hello_proxy zahir-hello-proxy
terraform import aws_lambda_permission.apigw zahir-hello-proxy/apigw-invoke

# API Gateway
terraform import aws_api_gateway_rest_api.main         q9gzox7h34
terraform import aws_api_gateway_method.root_get       q9gzox7h34/0gz3qjpy1c/GET
terraform import aws_api_gateway_integration.root_get  q9gzox7h34/0gz3qjpy1c/GET
terraform import aws_api_gateway_deployment.main       q9gzox7h34/dkyaab
terraform import aws_api_gateway_stage.prod            q9gzox7h34/prod

# VPC + Networking (previously eksctl-managed, now Terraform-managed)
terraform import aws_vpc.main                           vpc-04031749c8b836ba7
terraform import aws_subnet.public_1b                   subnet-0af9da2aa1bda019d
terraform import aws_subnet.public_1f                   subnet-09316561ce8129bce
terraform import aws_subnet.private_1b                  subnet-04947bfff2536a195
terraform import aws_subnet.private_1f                  subnet-00e80835781aa3152
terraform import aws_internet_gateway.main              igw-0ce7bccf64c353e2a
terraform import aws_eip.nat                            eipalloc-069f3df9eff06a346
terraform import aws_nat_gateway.main                   nat-0e79d8e0ecd6ebdc9
terraform import aws_route_table.public                 rtb-0da2b5691e7d8fe06
terraform import aws_route_table.private_1b             rtb-028238e18dc158ba4
terraform import aws_route_table.private_1f             rtb-0672ea0641c3ad2ee
terraform import aws_route_table_association.public_1b  subnet-0af9da2aa1bda019d/rtb-0da2b5691e7d8fe06
terraform import aws_route_table_association.public_1f  subnet-09316561ce8129bce/rtb-0da2b5691e7d8fe06
terraform import aws_route_table_association.private_1b subnet-04947bfff2536a195/rtb-028238e18dc158ba4
terraform import aws_route_table_association.private_1f subnet-00e80835781aa3152/rtb-0672ea0641c3ad2ee
```

After all imports, run `terraform plan` — it should show **no changes** or only
non-destructive diffs (e.g. `source_code_hash` for Lambda, which Terraform will update
on next apply).

### How apply works (automatic)

Every push to `main` triggers:
1. `terraform init` — initialises providers and S3 backend
2. `terraform validate` — syntax check
3. `terraform plan` — shows what would change
4. `terraform apply -auto-approve` — applies changes without manual approval

No human approval step. Changes to `.tf` files are applied automatically.

### How destroy works — from GitHub UI

1. Go to **Actions** → **Terraform Destroy**
2. Click **Run workflow**
3. In the `confirm` field type exactly: `DESTROY`
4. Click **Run workflow**

The workflow will abort if the input is anything other than `DESTROY`.

### How destroy works — from GitHub CLI

```bash
gh workflow run terraform-destroy.yml \
  --repo ZAZA-del/zahir-devops \
  -f confirm=DESTROY
```

Watch the run:
```bash
gh run watch --repo ZAZA-del/zahir-devops
```

### Destroy scope

`terraform destroy` removes:
- EKS cluster + node group
- IAM roles and policy attachments
- ECR repositories (including all stored images — `force_delete = true`)
- Lambda function
- API Gateway + stage

It does **not** remove:
- The S3 bucket and DynamoDB table used for Terraform state (bootstrap resources)
- Kubernetes workload YAMLs in `k8s/` (these are redeployable via kubectl)

---

## Logging Architecture

```
Application pods
    ↓
Container stdout/stderr
    ↓
Filebeat DaemonSet (reads /var/log/containers)
    ↓
Elasticsearch (index: zahir-logs-YYYY.MM.DD)
    ↓
Kibana (visualization + dashboards)
```

Access Kibana at: http://a559a8fcbad304edba1b6a467118b587-708286872.us-east-1.elb.amazonaws.com:5601

---

## Infrastructure

| Resource | Name | Details |
|----------|------|---------|
| EKS Cluster | `zahir-cluster` | us-east-1, k8s 1.30 |
| Node Group | `zahir-nodes` | 2× t3.medium |
| ECR Backend | `zahir-backend` | Spring Boot image |
| ECR Frontend | `zahir-frontend` | Angular/nginx image |
| k8s Namespace | `zahir` | All workloads |
| Lambda | `zahir-hello-proxy` | Python 3.13, API Gateway |

---

## Deliverables

See [`/deliverables/`](./deliverables/) for:
- `screenshots/k8s-pods-services.txt` — kubectl output of all pods/services
- `screenshots/backend-endpoint.txt` — backend API responses
- `screenshots/frontend-status.txt` — frontend HTTP status + cache headers
- `screenshots/kibana-status.txt` — Kibana status and log count
- `screenshots/lambda-endpoint.txt` — Lambda serverless endpoint response
