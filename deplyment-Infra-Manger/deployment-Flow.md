# Infrastructure Manager Deployment Flow

This document explains how Infrastructure Manager deploys resources using our multi-repository setup.

## Repository Architecture

Our infrastructure code is split across two repositories for better modularity and reusability:

### Repository 1: Cognitech-GCP-Infrastructure-Manager-repo (Modules)
**Purpose**: Contains reusable Terraform modules

```
Cognitech-GCP-Infrastructure-Manager-repo/
└── Infrastructure-Manger/
    └── modules/
        ├── Org/          # Organization, folders, projects
        ├── IAM/          # IAM bindings, service accounts, roles
        ├── Network/      # VPC, subnets, firewall rules
        └── ...
```

**Location**: 
- GitHub: `https://github.com/KahBrightTech/Cognitech-GCP-Infrastructure-Manager-repo`
- Local: `C:\Users\Owner\Downloads\GitRepos\cognitech-repos\Cognitech-GCP-Infrastructure-Manager-repo`

---

### Repository 2: Cognitech-GCP-Network-repo (Deployments)
**Purpose**: Contains deployment configurations that use the modules

```
Cognitech-GCP-Network-repo/
└── deplyment-Infra-Manger/
    └── cognitechllc/
        ├── Environment-Config/     # Deployment config files
        │   └── Playgroud/
        │       └── dev-project/
        │           ├── deployment-config.yaml
        │           └── deploy.ps1
        └── Playground/             # Terraform code
            └── dev-project/
                ├── main.tf         # Calls modules from Repo 1
                ├── variables.tf
                ├── provider.tf
                ├── outputs.tf
                └── versions.tf
```

**Location**:
- GitHub: `https://github.com/KahBrightTech/Cognitech-GCP-Network-repo`
- Local: `C:\Users\Owner\Downloads\GitRepos\cognitech-repos\Cognitech-GCP-Network-repo`

---

## How the Deployment Works

### Step 1: Local Development

You edit files on your local machine:

```
C:\Users\Owner\...\Cognitech-GCP-Network-repo\deplyment-Infra-Manger\cognitechllc\Playground\dev-project\main.tf
```

Example `main.tf`:
```terraform
# This file calls modules from the Infrastructure-Manager-repo
module "iam" {
  source = "git::https://github.com/KahBrightTech/Cognitech-GCP-Infrastructure-Manager-repo.git//Infrastructure-Manger/modules/IAM?ref=v1.0.0"
  
  iam = var.iam
}
```

### Step 2: Push to GitHub

```bash
git add .
git commit -m "Update IAM configuration"
git push origin main
```

Now your code is available at:
```
https://github.com/KahBrightTech/Cognitech-GCP-Network-repo
```

### Step 3: Trigger Infrastructure Manager Deployment

Run the deployment using one of these methods:

#### Method A: Using the deploy.ps1 script (Auto-detects paths)

```powershell
cd deplyment-Infra-Manger\cognitechllc\Environment-Config\Playgroud\dev-project
.\deploy.ps1 -ProjectId "YOUR_PROJECT_ID"
```

#### Method B: Using gcloud CLI directly

```bash
gcloud infra-manager deployments apply \
    projects/YOUR_PROJECT_ID/locations/us-central1/deployments/cognitechllc-playground-dev-project \
    --service-account=infra-deployer@cognitech-playground.iam.gserviceaccount.com \
    --git-source-repo=https://github.com/KahBrightTech/Cognitech-GCP-Network-repo \
    --git-source-ref=main \
    --git-source-directory=deplyment-Infra-Manger/cognitechllc/Playground/dev-project
```

### Step 4: Infrastructure Manager Execution

Here's what happens inside Google Cloud:

```
┌─────────────────────────────────────────────────────────────────┐
│                    Infrastructure Manager                        │
│                    (Running in GCP Cloud)                        │
└─────────────────────────────────────────────────────────────────┘
                              │
                              │ 1. Fetch deployment code
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│  GitHub: Cognitech-GCP-Network-repo                             │
│  Path: deplyment-Infra-Manger/cognitechllc/Playground/         │
│        dev-project/                                              │
│  Files: main.tf, variables.tf, provider.tf, etc.               │
└─────────────────────────────────────────────────────────────────┘
                              │
                              │ 2. Parse main.tf and find module sources
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│  main.tf contains:                                              │
│  module "iam" {                                                 │
│    source = "git::https://github.com/.../                      │
│             Infrastructure-Manager-repo.git//...IAM?ref=v1.0.0"│
│  }                                                              │
└─────────────────────────────────────────────────────────────────┘
                              │
                              │ 3. Fetch module code
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│  GitHub: Cognitech-GCP-Infrastructure-Manager-repo              │
│  Path: Infrastructure-Manger/modules/IAM/                       │
│  Files: main.tf, variables.tf, outputs.tf                      │
└─────────────────────────────────────────────────────────────────┘
                              │
                              │ 4. Run Terraform
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│  Terraform Plan & Apply                                         │
│  - Create IAM bindings                                          │
│  - Create service accounts                                      │
│  - Apply folder permissions                                     │
└─────────────────────────────────────────────────────────────────┘
                              │
                              │ 5. Create resources
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│                    Google Cloud Platform                         │
│  Resources Created:                                             │
│  - IAM bindings                                                 │
│  - Service accounts                                             │
│  - Folder permissions                                           │
└─────────────────────────────────────────────────────────────────┘
```

---

## Key Points

### 1. **Why Two Repositories?**

- **Modules Repository**: Reusable components shared across multiple deployments
- **Deployment Repository**: Environment-specific configurations

**Benefits**:
- ✅ Modules can be versioned independently (using git tags like `v1.0.0`)
- ✅ One module can be used by multiple environments
- ✅ Changes to modules don't automatically affect all deployments
- ✅ Clear separation of concerns

### 2. **Why GitHub Instead of Local Files?**

Infrastructure Manager runs **in Google Cloud**, not on your local machine. It cannot access:
- `C:\Users\Owner\...` (your local files)

It CAN access:
- `https://github.com/...` (public/private repos you give it access to)

**Workflow**:
```
Your Computer (Edit) → GitHub (Store) → Infrastructure Manager (Deploy)
```

### 3. **How Modules Are Fetched**

When Infrastructure Manager reads your `main.tf`, it sees module sources like:

```terraform
source = "git::https://github.com/KahBrightTech/Cognitech-GCP-Infrastructure-Manager-repo.git//Infrastructure-Manger/modules/IAM?ref=v1.0.0"
```

Terraform automatically:
1. Clones the repository
2. Checks out the specified ref (tag/branch/commit)
3. Navigates to the specified path (`//Infrastructure-Manger/modules/IAM`)
4. Uses that module code

**You don't need to do anything special** - Terraform handles this automatically!

### 4. **Service Account Context**

The deployment runs as:
```
serviceAccount: "infra-deployer@cognitech-playground.iam.gserviceaccount.com"
```

This service account needs:
- **Project-level**: `roles/config.agent` (for Infrastructure Manager)
- **Org-level**: `roles/resourcemanager.folderAdmin`, `roles/resourcemanager.projectCreator`, `roles/iam.securityAdmin` (to create resources)

---

## Deployment Configuration Reference

### deployment-config.yaml

```yaml
deployment:
  name: "cognitechllc-playground-dev-project"  # Unique deployment name
  location: "us-central1"                       # Where metadata is stored

serviceAccount: "infra-deployer@cognitech-playground.iam.gserviceaccount.com"

terraformConfig:
  gitSource:
    repository: "https://github.com/KahBrightTech/Cognitech-GCP-Network-repo"
    ref: "main"                                 # Branch/tag/commit
    subpath: "deplyment-Infra-Manger/cognitechllc/Playground/dev-project"
```

**What each field does**:
- `repository`: Points to the **deployment repo** (Network-repo)
- `ref`: Which branch/tag to deploy from
- `subpath`: Path within the repo where Terraform code lives (main.tf, etc.)
- `serviceAccount`: Which service account to impersonate for the deployment

---

## Complete Deployment Example

### Scenario: Deploy IAM configuration to Playground dev-project

**Step 1**: Edit IAM configuration locally
```powershell
cd C:\Users\Owner\...\Cognitech-GCP-Network-repo\deplyment-Infra-Manger\cognitechllc\Playground\dev-project
# Edit variables.tf or terraform.tfvars
```

**Step 2**: Commit and push
```bash
git add .
git commit -m "Update IAM bindings for dev-project"
git push origin main
```

**Step 3**: Deploy
```powershell
cd ..\Environment-Config\Playgroud\dev-project
.\deploy.ps1 -ProjectId "cognitech-playground"
```

**Step 4**: Monitor
```bash
gcloud infra-manager deployments describe \
    cognitechllc-playground-dev-project \
    --location=us-central1 \
    --project=cognitech-playground
```

---

## Troubleshooting

### "Module not found" error
- **Cause**: Module repository is private and Infrastructure Manager can't access it
- **Solution**: Ensure the repository is public or configure GitHub authentication

### "Permission denied" error
- **Cause**: Service account lacks necessary permissions
- **Solution**: Grant required roles at org/folder/project level

### "Subpath not found" error
- **Cause**: The path in deployment-config.yaml doesn't exist in the repo
- **Solution**: Verify the subpath matches your actual directory structure

### Changes not deploying
- **Cause**: You edited local files but didn't push to GitHub
- **Solution**: Always `git push` before deploying

---

## Best Practices

1. **Always commit and push before deploying**
   - Infrastructure Manager only sees what's on GitHub, not your local changes

2. **Use module versions (git tags)**
   - `?ref=v1.0.0` ensures consistent deployments
   - Prevents breaking changes from affecting existing deployments

3. **Test in Playground first**
   - Validate changes in Playground before deploying to Preprod/Production

4. **Use the deploy.ps1 script**
   - Auto-detects paths, reducing manual errors
   - Consistent deployment process

5. **Document environment-specific variables**
   - Keep terraform.tfvars up to date
   - Use comments to explain non-obvious values

---

## Summary

**Your infrastructure deployment flow**:

```
┌─────────────────┐
│  Local Files    │  You edit Terraform code
│  (Your PC)      │
└────────┬────────┘
         │ git push
         ▼
┌─────────────────┐
│  GitHub Repo    │  Code storage (Network-repo)
│  (Deployment)   │
└────────┬────────┘
         │
         │ Infrastructure Manager fetches
         ▼
┌─────────────────┐
│  Infrastructure │  Reads main.tf, sees module sources
│  Manager        │
└────────┬────────┘
         │
         │ Terraform fetches modules
         ▼
┌─────────────────┐
│  GitHub Repo    │  Module code (Infrastructure-Manager-repo)
│  (Modules)      │
└────────┬────────┘
         │
         │ Apply Terraform
         ▼
┌─────────────────┐
│  GCP Resources  │  Folders, projects, IAM, networks created
└─────────────────┘
```

**This setup provides**:
- ✅ GitOps workflow (version controlled deployments)
- ✅ Reusable modules across environments
- ✅ Centralized deployment management
- ✅ Audit trail of all changes
- ✅ Consistent, repeatable deployments
