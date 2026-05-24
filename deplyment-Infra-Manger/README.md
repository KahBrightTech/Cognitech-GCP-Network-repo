# GCP Infrastructure Manager Deployment Guide

This directory contains Infrastructure Manager (IM) deployment configurations for managing GCP organizational resources using Terraform.

## Overview

Infrastructure Manager is Google Cloud's fully managed service for deploying and managing infrastructure as code using Terraform. It provides:
- Centralized deployment management
- Built-in state management
- Service account-based authentication
- GitOps integration
- Deployment previews and rollbacks

## Directory Structure

```
deplyment-Infra-Manger/
├── README.md (this file)
└── cognitechllc/
    ├── Playground/
    │   ├── deployment-config.yaml
    │   ├── main.tf
    │   ├── variables.tf
    │   ├── provider.tf
    │   ├── outputs.tf
    │   └── versions.tf
    └── Preprod/
        └── (similar structure)
```

## Prerequisites

1. **GCP Project**: A GCP project with Infrastructure Manager API enabled
2. **Authentication**: Appropriate permissions (see below)
3. **gcloud CLI**: Installed and configured
4. **Service Account**: Created with necessary permissions

### Required APIs

Enable the following APIs in your GCP project:

```bash
gcloud services enable config.googleapis.com
gcloud services enable cloudresourcemanager.googleapis.com
gcloud services enable iam.googleapis.com
gcloud services enable compute.googleapis.com
```

### Service Account Permissions

Create a service account with the following roles:

```bash
# Create service account
gcloud iam service-accounts create infra-deployer \
    --display-name="Infrastructure Manager Deployer" \
    --project=YOUR_PROJECT_ID

# Grant necessary roles
gcloud projects add-iam-policy-binding YOUR_PROJECT_ID \
    --member="serviceAccount:infra-deployer@YOUR_PROJECT_ID.iam.gserviceaccount.com" \
    --role="roles/config.agent"

gcloud organizations add-iam-policy-binding YOUR_ORG_ID \
    --member="serviceAccount:infra-deployer@YOUR_PROJECT_ID.iam.gserviceaccount.com" \
    --role="roles/resourcemanager.folderAdmin"

gcloud organizations add-iam-policy-binding YOUR_ORG_ID \
    --member="serviceAccount:infra-deployer@YOUR_PROJECT_ID.iam.gserviceaccount.com" \
    --role="roles/resourcemanager.projectCreator"

gcloud organizations add-iam-policy-binding YOUR_ORG_ID \
    --member="serviceAccount:infra-deployer@YOUR_PROJECT_ID.iam.gserviceaccount.com" \
    --role="roles/iam.securityAdmin"
```

## Deployment via Infrastructure Manager

### Step 1: Update Configuration

Edit the `deployment-config.yaml` file in your environment directory:

```yaml
deployment:
  name: "your-deployment-name"
  location: "us-central1"

serviceAccount: "infra-deployer@your-project.iam.gserviceaccount.com"

terraformConfig:
  gitSource:
    repository: "https://github.com/KahBrightTech/Cognitech-GCP-Network-repo"
    ref: "main"
    subpath: "deplyment-Infra-Manger/cognitechllc/Playground"
```

### Step 2: Create Deployment

Navigate to your environment directory and create the deployment:

```bash
# Navigate to the environment directory
cd deplyment-Infra-Manger/cognitechllc/Playground

# Set your project
gcloud config set project YOUR_PROJECT_ID

# Create the deployment
gcloud infra-manager deployments apply \
    projects/YOUR_PROJECT_ID/locations/us-central1/deployments/cognitechllc-playground-deployment \
    --service-account=infra-deployer@YOUR_PROJECT_ID.iam.gserviceaccount.com \
    --git-source-repo=https://github.com/KahBrightTech/Cognitech-GCP-Network-repo \
    --git-source-ref=main \
    --git-source-directory=deplyment-Infra-Manger/cognitechllc/Playground \
    --labels=environment=playground,managed-by=infrastructure-manager
```

### Step 3: Preview Changes (Optional)

Before applying, you can preview the changes:

```bash
gcloud infra-manager previews create \
    projects/YOUR_PROJECT_ID/locations/us-central1/previews/playground-preview-$(date +%s) \
    --service-account=infra-deployer@YOUR_PROJECT_ID.iam.gserviceaccount.com \
    --git-source-repo=https://github.com/KahBrightTech/Cognitech-GCP-Network-repo \
    --git-source-ref=main \
    --git-source-directory=deplyment-Infra-Manger/cognitechllc/Playground
```

### Step 4: Monitor Deployment

Check the deployment status:

```bash
# List all deployments
gcloud infra-manager deployments list \
    --location=us-central1 \
    --project=YOUR_PROJECT_ID

# Describe a specific deployment
gcloud infra-manager deployments describe \
    cognitechllc-playground-deployment \
    --location=us-central1 \
    --project=YOUR_PROJECT_ID

# View deployment logs
gcloud infra-manager deployments describe \
    cognitechllc-playground-deployment \
    --location=us-central1 \
    --project=YOUR_PROJECT_ID \
    --format="value(latestRevision)"
```

### Step 5: Export Deployment State (Optional)

Export Terraform state if needed:

```bash
gcloud infra-manager deployments export-statefile \
    cognitechllc-playground-deployment \
    --location=us-central1 \
    --project=YOUR_PROJECT_ID \
    --state-file=./terraform.tfstate
```

## Updating an Existing Deployment

To update a deployment with new changes:

```bash
# Simply re-run the apply command with updated Git ref or directory
gcloud infra-manager deployments apply \
    projects/YOUR_PROJECT_ID/locations/us-central1/deployments/cognitechllc-playground-deployment \
    --service-account=infra-deployer@YOUR_PROJECT_ID.iam.gserviceaccount.com \
    --git-source-repo=https://github.com/KahBrightTech/Cognitech-GCP-Network-repo \
    --git-source-ref=main \
    --git-source-directory=deplyment-Infra-Manger/cognitechllc/Playground
```

## Deleting a Deployment

To destroy resources and delete the deployment:

```bash
# Delete the deployment (this will destroy the resources)
gcloud infra-manager deployments delete \
    cognitechllc-playground-deployment \
    --location=us-central1 \
    --project=YOUR_PROJECT_ID \
    --delete-policy=DELETE
```

## Using with GitHub Actions (CI/CD)

For automated deployments via GitHub Actions, update your workflow to use Infrastructure Manager:

```yaml
name: Deploy with Infrastructure Manager

on:
  push:
    branches:
      - main
    paths:
      - 'deplyment-Infra-Manger/cognitechllc/Playground/**'

jobs:
  deploy:
    runs-on: ubuntu-latest
    permissions:
      contents: read
      id-token: write

    steps:
      - name: Checkout
        uses: actions/checkout@v4

      - name: Authenticate to Google Cloud
        uses: google-github-actions/auth@v2
        with:
          workload_identity_provider: 'projects/PROJECT_NUMBER/locations/global/workloadIdentityPools/POOL_ID/providers/PROVIDER_ID'
          service_account: 'infra-deployer@YOUR_PROJECT_ID.iam.gserviceaccount.com'

      - name: Set up Cloud SDK
        uses: google-github-actions/setup-gcloud@v2

      - name: Deploy with Infrastructure Manager
        run: |
          gcloud infra-manager deployments apply \
            projects/${{ secrets.GCP_PROJECT_ID }}/locations/us-central1/deployments/cognitechllc-playground-deployment \
            --service-account=infra-deployer@${{ secrets.GCP_PROJECT_ID }}.iam.gserviceaccount.com \
            --git-source-repo=https://github.com/KahBrightTech/Cognitech-GCP-Network-repo \
            --git-source-ref=${{ github.ref_name }} \
            --git-source-directory=deplyment-Infra-Manger/cognitechllc/Playground \
            --async
```

## Troubleshooting

### Common Issues

1. **Permission Denied**
   - Ensure the service account has all required roles
   - Check organization-level permissions

2. **Deployment Fails**
   - Check deployment logs: `gcloud infra-manager deployments describe DEPLOYMENT_NAME --location=LOCATION`
   - Verify Terraform configuration syntax
   - Ensure all required variables are defined

3. **State Lock Issues**
   - Infrastructure Manager handles state locking automatically
   - If stuck, delete and recreate the deployment

### Useful Commands

```bash
# List all deployments
gcloud infra-manager deployments list --location=us-central1

# Get deployment outputs
gcloud infra-manager deployments describe DEPLOYMENT_NAME \
    --location=us-central1 \
    --format="value(terraformOutputs)"

# View deployment history
gcloud infra-manager revisions list \
    --deployment=DEPLOYMENT_NAME \
    --location=us-central1
```

## Best Practices

1. **Version Control**: Always use Git references (tags or commits) for production deployments
2. **Previews**: Use preview mode to validate changes before applying
3. **Labels**: Add meaningful labels for tracking and cost allocation
4. **Service Accounts**: Use dedicated service accounts with minimal required permissions
5. **State Management**: Let Infrastructure Manager handle state; avoid manual state manipulation
6. **Testing**: Test changes in Playground before deploying to Preprod/Production

## Resources

- [Google Cloud Infrastructure Manager Documentation](https://cloud.google.com/infrastructure-manager/docs)
- [Infrastructure Manager CLI Reference](https://cloud.google.com/sdk/gcloud/reference/infra-manager)
- [Terraform GCP Provider](https://registry.terraform.io/providers/hashicorp/google/latest/docs)

## Support

For issues or questions:
- Contact: platform-team@cognitechllc.org
- Internal Wiki: [Link to internal documentation]
- Slack Channel: #platform-engineering