# CLAUDE.md

Always answer in Japanese.

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is a full-stack microservices application demonstrating Azure Container Apps with Dapr integration. It's a product management system designed for learning cloud-native development practices, IaC (Infrastructure as Code), and CI/CD pipelines.

## Key Technologies

- **Backend**: Python 3.13.3 with Flask 3.1.1, Dapr 1.15.0, Gunicorn
- **Frontend**: Next.js 15.2.4 with TypeScript, Tailwind CSS, shadcn/ui
- **Infrastructure**: Terraform, Docker, GitHub Actions, Azure Developer CLI (azd)
- **Azure Services**: Container Apps, Container Registry, Cosmos DB, Key Vault, Virtual Network

## Development Commands

### Backend Development

```bash
# Setup virtual environment and install dependencies
cd src/backend
python -m venv .venv
source .venv/bin/activate  # On Windows: .venv\Scripts\activate
pip install -r requirements.txt

# Configure Cosmos DB connection for local development
cd components/
cp secrets.sample.json secrets.json  # Edit with your Cosmos DB credentials

# Run backend with Dapr
cd ../
dapr run --app-id product-api --app-port 5002 --dapr-http-port 3500 --resources-path ./components/ python main.py
```

### Frontend Development

```bash
# Install dependencies
cd src/frontend
npm install

# Run development server
npm run dev

# Build for production
npm run build

# Lint code
npm run lint
```

### Azure Deployment

```bash
# Login to Azure
azd auth login

# Deploy everything (infrastructure + apps)
azd up

# Deploy only infrastructure
azd provision --preview
azd provision

# Deploy individual services
azd deploy frontend
azd deploy backend

# Tear down all resources
azd down
```

### Docker Build Commands

```bash
# Build images locally
docker build -t frontend:latest src/frontend/
docker build -t backend:latest src/backend/

# Build with Azure Container Registry (via azd)
azd package
```

## Infrastructure Management

The infrastructure is managed using Terraform with all configuration files located in the `/infra/` directory:

- **main.tf**: Core infrastructure resources (Container Apps, VNet, Cosmos DB, etc.)
- **variables.tf**: Input variable definitions
- **outputs.tf**: Output values (URLs, resource IDs, etc.)
- **provider.tf**: Azure provider configuration
- **backend.tf**: Terraform state storage configuration
- **locals.tf**: Local values and computed variables

### Terraform Commands

```bash
# Initialize Terraform
cd infra
terraform init

# Preview infrastructure changes
terraform plan

# Apply infrastructure changes
terraform apply

# Destroy infrastructure
terraform destroy
```

## Architecture Overview

The application consists of two main services:

1. **Backend API** (`/src/backend/`): Flask REST API providing CRUD operations for products, integrated with Dapr for state management (Cosmos DB) and secrets (Key Vault)

   - Endpoints: `/products` (GET, POST), `/products/<id>` (GET, PUT, DELETE), `/healthz`

2. **Frontend** (`/src/frontend/`): Next.js application with Server Actions for backend communication
   - Components: `ProductForm.tsx` (create/edit), `ProductTable.tsx` (display)

## Dapr Components

The backend uses Dapr components (`/src/backend/components/`) for:

- **State Store**: Cosmos DB abstraction with separate configs for local and Azure environments
- **Secret Store**: Key Vault integration for production, local secrets.json for development

## CI/CD Workflows

GitHub Actions workflows handle:

- **terraform.yml**: Infrastructure deployment with Terraform
- **frontend.yml**: Frontend deployment triggered on changes to `src/frontend/`
- **backend.yml**: Backend deployment triggered on changes to `src/backend/`
- **msdevopssec.yml**: Security scanning

## Testing APIs

Use the `rest.http` file with VS Code REST Client extension to test API endpoints locally or in production.
