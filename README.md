# Zahir DevOps — Academic Compliant Cloud Project

Full-stack cloud-native deployment meeting academic requirements:
**Java Spring Boot + Angular + Kubernetes (EKS) + Elasticsearch + Kibana + AWS Lambda + GitHub Actions CI/CD**

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

On every push to `main`:

```
Test Backend      →  mvn verify (JUnit)
Test Frontend     →  ng build --configuration production
        ↓
Build & Push      →  docker buildx --platform linux/amd64
                     push zahir-backend:sha, zahir-frontend:sha to ECR
        ↓
Deploy to EKS     →  aws eks update-kubeconfig
                     kubectl apply -f k8s/
                     kubectl rollout status
```

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
