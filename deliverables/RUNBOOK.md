# Zahir DevOps — Runbook: How to Use, Deploy, and Destroy

## Quick Reference

| Action | How |
|--------|-----|
| Deploy (normal push) | `git push origin main` |
| Plan only (PR) | Open a pull request → plan posts as PR comment |
| Destroy everything | `gh workflow run terraform-destroy.yml --repo ZAZA-del/zahir-devops -f confirm=DESTROY` |
| See live app URLs | `cd infra/terraform && terraform output` |

---

## Prerequisites

### Local tools
```bash
# Required
aws CLI      # configured with zahir-admin credentials
terraform    # >= 1.5.0
kubectl      # for manual k8s interaction
gh           # GitHub CLI, authenticated as ZAZA-del

# Verify
aws sts get-caller-identity          # should show account 143575007958
terraform version                    # should be >= 1.5.0
gh auth status                       # should show ZAZA-del logged in
```

### GitHub Secrets (already set)
| Secret | Purpose |
|--------|---------|
| `AWS_ACCESS_KEY_ID` | CI AWS auth |
| `AWS_SECRET_ACCESS_KEY` | CI AWS auth |
| `AWS_ACCOUNT_ID` | ECR URL construction |

---

## Scenario 1 — Normal Code Push (Plan + Apply + Deploy)

Push any change to `main` and the full pipeline runs automatically:

```bash
git add .
git commit -m "your change"
git push origin main
```

**Pipeline stages (all automatic):**
1. `Test Backend` — `mvn verify`
2. `Build Frontend` — `ng build --configuration production`
3. `Terraform Plan` — shows what infrastructure would change
4. `Terraform Apply` — applies infrastructure changes
5. `Build & Push Images` — Docker build → ECR push
6. `Deploy to EKS` — `kubectl apply` + rollout + update Terraform URL outputs

**Watch it:**
```bash
gh run watch --repo ZAZA-del/zahir-devops
```

---

## Scenario 2 — Pull Request (Plan Only, No Apply)

Open a PR against `main` — Terraform plan runs and posts the output as a PR comment.
No infrastructure is changed. No images are pushed. No deploy happens.

```bash
git checkout -b my-feature
git push origin my-feature
gh pr create --title "My feature" --body "..."
```

The plan comment appears automatically on the PR within ~2 minutes.

---

## Scenario 3 — Destroy Everything

Wipes **all** AWS infrastructure managed by Terraform:
VPC, EKS cluster + nodes, IAM roles, ECR repos (images deleted), Lambda, API Gateway, security groups, NAT/IGW.

### From GitHub CLI (recommended)
```bash
gh workflow run terraform-destroy.yml \
  --repo ZAZA-del/zahir-devops \
  -f confirm=DESTROY

# Watch progress
gh run watch --repo ZAZA-del/zahir-devops
```

### From GitHub UI
1. Go to **Actions** → **Terraform Destroy**
2. Click **Run workflow**
3. Type exactly `DESTROY` in the confirm field
4. Click **Run workflow**

**Destroy sequence (handled automatically by the workflow):**
1. `kubectl delete namespace zahir` — removes LoadBalancer services so AWS cleans up ELB security groups
2. Wait up to 3 min for ELB SGs to disappear
3. `terraform destroy -target=aws_eks_node_group.main` — detaches node ENIs first
4. `sleep 60` — lets ENIs fully release
5. Revoke circular SG ingress rules (cluster_shared ↔ eks-cluster-sg)
6. `terraform destroy` — deletes everything cleanly

**What is NOT destroyed:**
- S3 bucket `zahir-terraform-state-143575007958` (Terraform state)
- DynamoDB table `zahir-terraform-locks` (state locking)

---

## Scenario 4 — Rebuild from Zero (After Destroy)

After a destroy, push to `main` to rebuild everything from scratch:

```bash
# Option A: push an actual change
git commit -m "fix: ..." && git push origin main

# Option B: push an empty commit to trigger rebuild
git commit --allow-empty -m "rebuild: trigger full terraform apply"
git push origin main
```

**What happens:**
1. Terraform creates: VPC → subnets → IGW → NAT → SGs → EKS cluster → add-ons (vpc-cni, kube-proxy) → node group → coredns → ECR → Lambda → API Gateway
2. Docker images are built and pushed to the new ECR repos
3. Kubernetes workloads deploy to the new cluster
4. Terraform outputs are updated with the new ELB hostnames

**Total time:** ~15–20 minutes (EKS cluster creation takes ~10 min)

---

## Scenario 5 — Check Live App URLs

After any deploy, Terraform state holds the current URLs:

```bash
cd infra/terraform
terraform output
```

**Output:**
```
app_frontend_url = "http://<elb>.us-east-1.elb.amazonaws.com"
app_backend_url  = "http://<elb>.us-east-1.elb.amazonaws.com"
app_kibana_url   = "http://<elb>.us-east-1.elb.amazonaws.com:5601"
api_gateway_url  = "https://<id>.execute-api.us-east-1.amazonaws.com/prod/"
```

Or get a specific output:
```bash
terraform output app_frontend_url
terraform output api_gateway_url
```

---

## Scenario 6 — Smoke Test All Endpoints

```bash
# Read URLs from Terraform
BACKEND=$(terraform output -raw app_backend_url)
FRONTEND=$(terraform output -raw app_frontend_url)
LAMBDA=$(terraform output -raw api_gateway_url)

# Backend
curl $BACKEND/           # → "Backend is running"
curl $BACKEND/hello      # → "Hello World"

# Frontend → Backend proxy
curl $FRONTEND/api/hello  # → "Hello World"

# Lambda → Backend
curl $LAMBDA              # → {"source":"AWS Lambda","message":"Lambda → Spring Boot: Hello World"}

# Kibana status
KIBANA=$(terraform output -raw app_kibana_url)
curl -s $KIBANA/api/status | python3 -c "import sys,json; print(json.load(sys.stdin)['name'])"
```

---

## Scenario 7 — Manual kubectl Access

```bash
# Configure kubectl
aws eks update-kubeconfig --region us-east-1 --name zahir-cluster

# Check cluster
kubectl get nodes
kubectl get pods -n zahir
kubectl get svc -n zahir

# Logs
kubectl logs -n zahir deployment/zahir-backend
kubectl logs -n zahir deployment/zahir-frontend
```

---

## Scenario 8 — Local Development

```bash
# Full stack with Docker Compose
docker-compose up --build
# Backend:       http://localhost:8080
# Frontend:      http://localhost:80
# Elasticsearch: http://localhost:9200
# Kibana:        http://localhost:5601

# Backend only
cd backend && ./mvnw spring-boot:run

# Frontend only
cd frontend && npm install && ng serve
# → http://localhost:4200
```

---

## CI/CD Pipeline Reference

### Workflow files
| File | Trigger | Purpose |
|------|---------|---------|
| `.github/workflows/ci-cd.yml` | push to main / PR | Tests, Terraform plan/apply, Docker build, k8s deploy |
| `.github/workflows/terraform-destroy.yml` | manual only | Destroy all infrastructure |

### Job dependency graph
```
push to main:
  test-backend ──┬──► terraform-plan ──► terraform-apply ──┐
  test-frontend ─┘                                         │
                  └──────────────────────────────────────  │
  test-backend ──┬──► build-and-push ──────────────────────┴──► deploy
  test-frontend ─┘

pull_request:
  test-backend ──┬──► terraform-plan (posts comment, no apply)
  test-frontend ─┘
```

---

## Terraform Commands Reference

```bash
cd infra/terraform

# Initialize (first time or after provider changes)
terraform init

# See what would change
terraform plan

# Apply changes
terraform apply -auto-approve

# See current outputs
terraform output

# Destroy everything (prefer the GitHub workflow instead)
terraform destroy -auto-approve

# See what's in state
terraform state list

# Import an existing resource (one-time, if resource existed before Terraform)
terraform import aws_eks_cluster.main zahir-cluster
```

---

## Troubleshooting

### Nodes NotReady after rebuild
EKS add-ons (vpc-cni, kube-proxy, coredns) must install before nodes become Ready.
Managed by `addons.tf` — runs automatically. Wait 2–3 min after node group creation.

### Destroy fails with DependencyViolation on SG
The destroy workflow handles this automatically via the staged sequence.
If it still fails (e.g., ELB SGs not cleaned up in time), manually delete the k8s namespace first:
```bash
kubectl delete namespace zahir --wait=true
# wait ~60s, then re-trigger the destroy workflow
```

### Lambda returns error after rebuild
The backend ELB URL changes on every rebuild. CI updates it automatically in the deploy step.
If CI skipped (e.g., manual `terraform apply`), run:
```bash
BACKEND=$(kubectl get svc zahir-backend-svc -n zahir -o jsonpath='{.status.loadBalancer.ingress[0].hostname}')
cd infra/terraform
terraform apply -auto-approve -var="backend_lb_url=http://${BACKEND}"
```

### Terraform state lock stuck
```bash
cd infra/terraform
terraform force-unlock <LOCK_ID>
# Get LOCK_ID from the error message
```

### kubectl not configured
```bash
aws eks update-kubeconfig --region us-east-1 --name zahir-cluster
```
