# Zahir DevOps — Production-Ready Cloud Project

A fully automated DevOps deployment: Node.js API + React frontend on AWS ECS Fargate with CI/CD and OpenSearch logging.

---

## Live URLs

| Service | URL |
|---------|-----|
| **Frontend** | http://zahir-alb-592987015.us-east-1.elb.amazonaws.com |
| **Backend API** | http://zahir-alb-592987015.us-east-1.elb.amazonaws.com:8080 |
| **Health Check** | http://zahir-alb-592987015.us-east-1.elb.amazonaws.com:8080/health |
| **API Info** | http://zahir-alb-592987015.us-east-1.elb.amazonaws.com:8080/api/info |
| **OpenSearch Dashboards** | https://search-zahir-logs-vc2kg6vl2mip7zr5aaozpiquzm.us-east-1.es.amazonaws.com/_dashboards |
| **GitHub Repo** | https://github.com/ZAZA-del/zahir-devops |

---

## Architecture

```
                         ┌─────────────────────────────────────────┐
                         │              AWS us-east-1               │
                         │                                          │
Internet ──► ALB ──────► │  ┌──────────────┐  ┌─────────────────┐ │
             port 80     │  │ ECS Frontend │  │  ECS Backend    │ │
             port 8080   │  │ React+Vite   │  │ Node.js/Express │ │
                         │  │ nginx:alpine  │  │  node:22-alpine │ │
                         │  └──────────────┘  └────────┬────────┘ │
                         │                             │           │
                         │  ECR (zahir-backend)        │           │
                         │  ECR (zahir-frontend)       ▼           │
                         │                    CloudWatch Logs       │
                         │                         │                │
                         │                         ▼                │
                         │                  Lambda (shipper)        │
                         │                         │                │
                         │                         ▼                │
                         │                    OpenSearch            │
                         │                    (zahir-logs)          │
                         └─────────────────────────────────────────┘
```

### Components

| Component | Technology | Details |
|-----------|-----------|---------|
| Backend | Node.js 22 + Express | REST API on port 3001 |
| Frontend | React 18 + Vite | Served via nginx |
| Container Registry | AWS ECR | `zahir-backend`, `zahir-frontend` |
| Compute | AWS ECS Fargate | 256 CPU / 512MB per service |
| Load Balancer | AWS ALB | Port 80 (frontend), 8080 (backend) |
| Logs | CloudWatch → Lambda → OpenSearch | Domain: `zahir-logs` |
| CI/CD | GitHub Actions | test → build → push ECR → deploy ECS |

---

## API Endpoints

```
GET /health      → Service health status
GET /api         → API welcome + endpoint list
GET /api/info    → Stack info, uptime, memory usage
```

---

## Local Development

### Prerequisites
- Docker & Docker Compose
- Node.js 22+

### Run Locally

```bash
git clone https://github.com/ZAZA-del/zahir-devops.git
cd zahir-devops

# Start all services
docker-compose up --build

# Services:
# Frontend:           http://localhost:3000
# Backend API:        http://localhost:3001
# OpenSearch:         http://localhost:9200
# OpenSearch Dashboards: http://localhost:5601
```

### Run Without Docker

```bash
# Backend
cd backend
npm install
npm run dev     # http://localhost:3001

# Frontend (separate terminal)
cd frontend
npm install
npm run dev     # http://localhost:3000
```

### Run Tests

```bash
cd backend
npm test
```

---

## CI/CD Pipeline

On every push to `main`:

```
┌─────────┐    ┌──────────────────┐    ┌──────────────────────┐
│  Push   │───►│  1. Test         │───►│  2. Build & Push ECR │
│ to main │    │  npm test        │    │  docker buildx       │
└─────────┘    │  (jest coverage) │    │  linux/amd64         │
               └──────────────────┘    └──────────┬───────────┘
                                                   │
                                                   ▼
                                       ┌──────────────────────┐
                                       │  3. Deploy ECS       │
                                       │  force-new-deploy    │
                                       │  wait services-stable│
                                       └──────────────────────┘
```

GitHub Actions secrets required:
- `AWS_ACCESS_KEY_ID`
- `AWS_SECRET_ACCESS_KEY`
- `AWS_ACCOUNT_ID`

---

## Logging

Application logs flow:
1. Containers write to **CloudWatch Logs** (`/zahir/backend`, `/zahir/frontend`)
2. CloudWatch subscription triggers **Lambda** (`zahir-log-shipper`)
3. Lambda ships to **OpenSearch** domain (`zahir-logs`)
4. Visualize in **OpenSearch Dashboards**

CloudWatch Logs: [AWS Console](https://console.aws.amazon.com/cloudwatch/home?region=us-east-1#logsV2:log-groups/log-group/$252Fzahir$252Fbackend)

---

## Infrastructure

| Resource | Name | Region |
|----------|------|--------|
| ECS Cluster | `zahir-cluster` | us-east-1 |
| ECR Backend | `zahir-backend` | us-east-1 |
| ECR Frontend | `zahir-frontend` | us-east-1 |
| ALB | `zahir-alb` | us-east-1 |
| OpenSearch | `zahir-logs` | us-east-1 |
| Log Group Backend | `/zahir/backend` | us-east-1 |
| Log Group Frontend | `/zahir/frontend` | us-east-1 |

---

## Project Structure

```
zahir-devops/
├── backend/
│   ├── src/
│   │   ├── index.js          # Express app
│   │   └── index.test.js     # Jest tests
│   ├── Dockerfile            # node:22-alpine multi-stage
│   └── package.json
├── frontend/
│   ├── src/
│   │   ├── App.jsx           # React dashboard
│   │   └── main.jsx
│   ├── Dockerfile            # vite build + nginx
│   ├── nginx.conf
│   └── package.json
├── .github/
│   └── workflows/
│       └── ci-cd.yml         # Full CI/CD pipeline
├── docker-compose.yml        # Local dev with OpenSearch
└── README.md
```
