# Cognitech GCP Network Repository

This repository contains deployment configurations for Cognitech's GCP network infrastructure using Google Cloud Infrastructure Manager.

## 📁 Repository Structure

```
.
├── deployments/                    # Environment-specific deployments
│   └── int-production/
│       └── shared-account/
│           └── primary/
│               ├── main.tf                 # Module orchestration
│               ├── variables.tf            # Input variable definitions
│               ├── terraform.tfvars        # Actual values for this environment
│               ├── deployment-config.yaml  # Infrastructure Manager config
│               ├── versions.tf             # Terraform version constraints
│               ├── provider.tf             # Provider configuration
│               └── outputs.tf              # Deployment outputs
│
├── .github/
│   └── workflows/
│       └── deploy-infrastructure.yml  # GitHub Actions deployment workflow
│
└── README.md
```

## 🏗️ Architecture

This deployment creates:

### Folder Hierarchy
```
Organization (123456789012)
├── Production
│   ├── Networking (nested)
│   │   ├── Project: cognitech-prod-network-hub
│   │   └── Project: cognitech-prod-spoke-1
│   └── Security (nested)
│       └── Project: cognitech-prod-security-logs
│
└── Shared Services
    └── Monitoring (nested)
        └── Project: cognitech-shared-monitoring
```

### Components Created
- **4 Top-level folders** under the organization
- **3 Nested folders** for better organization
- **4 Projects** with appropriate APIs enabled
- **3 Service accounts** for automation
- **IAM bindings** at folder and project levels
- **Custom roles** for network operations

---

## 🚀 STEP-BY-STEP: Deploy via GitHub Actions

This is the **recommended approach** for automated, auditable infrastructure deployments.

### Prerequisites Checklist

Before you begin, ensure you have:
- [ ] A GCP Organization with billing enabled
- [ ] GitHub repository forked or cloned
- [ ] Organization admin access in GCP
- [ ] GitHub repository admin access

---

## Step 1: Setup GCP Project for Deployments

### 1.1 Create Deployment Project

**Option A: Via gcloud CLI**

```bash
# Set your organization ID
export ORG_ID="123456789012"  # Replace with your org ID
export BILLING_ACCOUNT="01234-56789A-BCDEF0"  # Replace with your billing account

# Create project for Infrastructure Manager
gcloud projects create cognitech-infra-deployment \
  --organization=$ORG_ID \
  --name="Infrastructure Deployment" \
  --set-as-default

# Link billing
gcloud billing projects link cognitech-infra-deployment \
  --billing-account=$BILLING_ACCOUNT
```

**Option B: Via Google Cloud Console**

1. **Navigate to Project Creation:**
   - Go to: https://console.cloud.google.com/projectcreate
   - Or: Click project dropdown (top bar) → **NEW PROJECT**

2. **Configure Project:**
   - **Project name:** `Infrastructure Deployment`
   - **Project ID:** `cognitech-infra-deployment` (click EDIT to customize)
   - **Organization:** Select your organization
   - **Location:** Select your organization

3. **Click CREATE**

4. **Link Billing Account:**
   - Go to: https://console.cloud.google.com/billing/linkedaccount?project=cognitech-infra-deployment
   - Or: **Navigation Menu** → **Billing** → **Account Management**
   - Click **LINK A BILLING ACCOUNT**
   - Select your billing account
   - Click **SET ACCOUNT**

### 1.2 Enable Required APIs

**Option A: Via gcloud CLI**

```bash
# Enable Infrastructure Manager and IAM APIs
gcloud services enable \
  config.googleapis.com \
  cloudresourcemanager.googleapis.com \
  iam.googleapis.com \
  serviceusage.googleapis.com \
  cloudbilling.googleapis.com \
  --project=cognitech-infra-deployment
```

**Option B: Via Google Cloud Console**

1. **Navigate to APIs & Services:**
   - Go to: https://console.cloud.google.com/apis/library?project=cognitech-infra-deployment
   - Or: **Navigation Menu** (☰) → **APIs & Services** → **Library**

2. **Enable each API:**
   - Search for "Infrastructure Manager API" → Click → **ENABLE**
   - Search for "Cloud Resource Manager API" → Click → **ENABLE**
   - Search for "Identity and Access Management (IAM) API" → Click → **ENABLE**
   - Search for "Service Usage API" → Click → **ENABLE**
   - Search for "Cloud Billing API" → Click → **ENABLE**

3. **Verify APIs are enabled:**
   - Go to: https://console.cloud.google.com/apis/dashboard?project=cognitech-infra-deployment
   - Check that all 5 APIs show as "Enabled"

---

## Step 2: Create Service Account for Deployments

### 2.1 Create Service Account

**Option A: Via gcloud CLI**

```bash
# Create service account
gcloud iam service-accounts create infra-deployer \
  --display-name="Infrastructure Manager Deployment Account" \
  --project=cognitech-infra-deployment

# Get the full email
export SA_EMAIL="infra-deployer@cognitech-infra-deployment.iam.gserviceaccount.com"
```

**Option B: Via Google Cloud Console**

1. **Navigate to Service Accounts:**
   - Go to: https://console.cloud.google.com/iam-admin/serviceaccounts?project=cognitech-infra-deployment
   - Or: **Navigation Menu** (☰) → **IAM & Admin** → **Service Accounts**

2. **Create Service Account:**
   - Click **+ CREATE SERVICE ACCOUNT**
   - **Service account name:** `infra-deployer`
   - **Service account ID:** `infra-deployer` (auto-filled)
   - **Description:** `Infrastructure Manager Deployment Account`
   - Click **CREATE AND CONTINUE**
   - Click **DONE** (we'll grant roles separately)

3. **Copy the Service Account Email:**
   - Note: `infra-deployer@cognitech-infra-deployment.iam.gserviceaccount.com`

### 2.2 Grant Organization-Level Permissions

**Option A: Via gcloud CLI**

```bash
# Required for folder and project creation
gcloud organizations add-iam-policy-binding $ORG_ID \
  --member="serviceAccount:$SA_EMAIL" \
  --role="roles/resourcemanager.folderCreator"

gcloud organizations add-iam-policy-binding $ORG_ID \
  --member="serviceAccount:$SA_EMAIL" \
  --role="roles/resourcemanager.projectCreator"

gcloud organizations add-iam-policy-binding $ORG_ID \
  --member="serviceAccount:$SA_EMAIL" \
  --role="roles/iam.organizationRoleAdmin"

gcloud organizations add-iam-policy-binding $ORG_ID \
  --member="serviceAccount:$SA_EMAIL" \
  --role="roles/billing.user"

# Grant Infrastructure Manager permissions
gcloud organizations add-iam-policy-binding $ORG_ID \
  --member="serviceAccount:$SA_EMAIL" \
  --role="roles/config.agent"
```

**Option B: Via Google Cloud Console**

1. **Navigate to Organization IAM:**
   - Go to: https://console.cloud.google.com/iam-admin/iam
   - At the top, change scope from project to your **Organization**
   - Or: Use organization picker (ensure you're viewing org-level IAM)

2. **Grant Permissions:**
   - Click **+ GRANT ACCESS**
   
   **Add the service account with these roles (repeat for each):**
   
   - **New principals:** `infra-deployer@cognitech-infra-deployment.iam.gserviceaccount.com`
   - **Role:** `Folder Creator`
   - Click **ADD ANOTHER ROLE** and add:
     - `Project Creator`
     - `Organization Role Administrator`
     - `Billing Account User`
     - `Infrastructure Manager Service Agent`
   
   - Click **SAVE**

3. **Verify Permissions:**
   - Search for `infra-deployer` in the IAM page
   - Verify all 5 roles are listed

### 2.3 Grant Project-Level Permissions

**Option A: Via gcloud CLI**

```bash
# Service account admin for creating service accounts in projects
gcloud projects add-iam-policy-binding cognitech-infra-deployment \
  --member="serviceAccount:$SA_EMAIL" \
  --role="roles/iam.serviceAccountAdmin"

# Service usage for enabling APIs
gcloud projects add-iam-policy-binding cognitech-infra-deployment \
  --member="serviceAccount:$SA_EMAIL" \
  --role="roles/serviceusage.serviceUsageAdmin"
```

**Option B: Via Google Cloud Console**

1. **Navigate to Project IAM:**
   - Go to: https://console.cloud.google.com/iam-admin/iam?project=cognitech-infra-deployment
   - Or: **Navigation Menu** (☰) → **IAM & Admin** → **IAM**

2. **Grant Permissions:**
   - Click **+ GRANT ACCESS**
   - **New principals:** `infra-deployer@cognitech-infra-deployment.iam.gserviceaccount.com`
   - **Role:** `Service Account Admin`
   - Click **ADD ANOTHER ROLE**
   - **Role:** `Service Usage Admin`
   - Click **SAVE**

---

## Step 3: Setup Workload Identity Federation for GitHub Actions

### 3.1 Create Workload Identity Pool

**Option A: Via gcloud CLI**

```bash
# Create pool
gcloud iam workload-identity-pools create "github-actions-pool" \
  --project="cognitech-infra-deployment" \
  --location="global" \
  --display-name="GitHub Actions Pool"

# Get pool ID
export WORKLOAD_IDENTITY_POOL_ID=$(gcloud iam workload-identity-pools describe github-actions-pool \
  --project="cognitech-infra-deployment" \
  --location="global" \
  --format="value(name)")

echo "Pool ID: $WORKLOAD_IDENTITY_POOL_ID"
```

**Option B: Via Google Cloud Console**

1. **Navigate to Workload Identity Federation:**
   - Go to: https://console.cloud.google.com/iam-admin/workload-identity-pools?project=cognitech-infra-deployment
   - Or: **Navigation Menu** (☰) → **IAM & Admin** → **Workload Identity Federation**

2. **Create Pool:**
   - Click **CREATE POOL**
   - **Name:** `github-actions-pool`
   - **Description:** `Pool for GitHub Actions authentication`
   - Click **CONTINUE**
   - Click **SAVE** (we'll add provider in next step)

### 3.2 Create Workload Identity Provider

**Option A: Via gcloud CLI**

```bash
# Replace YOUR_GITHUB_ORG with your GitHub organization or username
export GITHUB_ORG="KahBrightTech"

gcloud iam workload-identity-pools providers create-oidc "github-provider" \
  --project="cognitech-infra-deployment" \
  --location="global" \
  --workload-identity-pool="github-actions-pool" \
  --display-name="GitHub Provider" \
  --attribute-mapping="google.subject=assertion.sub,attribute.actor=assertion.actor,attribute.repository=assertion.repository,attribute.repository_owner=assertion.repository_owner" \
  --attribute-condition="assertion.repository_owner == '${GITHUB_ORG}'" \
  --issuer-uri="https://token.actions.githubusercontent.com"
```

**Option B: Via Google Cloud Console**

1. **Navigate to your Workload Identity Pool:**
   - Go to: https://console.cloud.google.com/iam-admin/workload-identity-pools?project=cognitech-infra-deployment
   - Click on **github-actions-pool**

2. **Add Provider:**
   - Click **ADD PROVIDER**
   - **Select provider:** `OpenID Connect (OIDC)`
   - Click **CONTINUE**

3. **Configure Provider:**
   - **Provider name:** `github-provider`
   - **Issuer (URL):** `https://token.actions.githubusercontent.com`
   - **Audiences:** `Default audience` (leave as is)
   - Click **CONTINUE**

4. **Configure Provider Attributes:**
   
   **Attribute Mappings:**
   ```
   google.subject          = assertion.sub
   attribute.actor         = assertion.actor
   attribute.repository    = assertion.repository
   attribute.repository_owner = assertion.repository_owner
   ```
   
   **Attribute Conditions (CEL expression):**
   ```
   assertion.repository_owner == "KahBrightTech"
   ```
   *(Replace `KahBrightTech` with your GitHub org)*
   
   - Click **SAVE**

### 3.3 Grant Service Account Access to GitHub

**Option A: Via gcloud CLI**

```bash
# Allow GitHub Actions from your repo to impersonate the service account
gcloud iam service-accounts add-iam-policy-binding $SA_EMAIL \
  --project="cognitech-infra-deployment" \
  --role="roles/iam.workloadIdentityUser" \
  --member="principalSet://iam.googleapis.com/${WORKLOAD_IDENTITY_POOL_ID}/attribute.repository/${GITHUB_ORG}/Cognitech-GCP-Network-repo"
```

**Option B: Via Google Cloud Console**

1. **Navigate to Service Accounts:**
   - Go to: https://console.cloud.google.com/iam-admin/serviceaccounts?project=cognitech-infra-deployment
   - Click on **infra-deployer** service account

2. **Grant Access:**
   - Click **PERMISSIONS** tab
   - Click **GRANT ACCESS**
   
   **Principal (use your values):**
   ```
   principalSet://iam.googleapis.com/projects/PROJECT_NUMBER/locations/global/workloadIdentityPools/github-actions-pool/attribute.repository/KahBrightTech/Cognitech-GCP-Network-repo
   ```
   
   Replace:
   - `PROJECT_NUMBER` with your project number (found in project settings)
   - `KahBrightTech` with your GitHub org
   - `Cognitech-GCP-Network-repo` with your repo name
   
   - **Role:** `Workload Identity User`
   - Click **SAVE**

**To get PROJECT_NUMBER via Console:**
- Go to: https://console.cloud.google.com/home/dashboard?project=cognitech-infra-deployment
- Find **Project number** in the **Project info** card

### 3.4 Get Provider Resource Name

**Option A: Via gcloud CLI**

```bash
# You'll need this for GitHub secrets
export WIF_PROVIDER=$(gcloud iam workload-identity-pools providers describe github-provider \
  --project="cognitech-infra-deployment" \
  --location="global" \
  --workload-identity-pool="github-actions-pool" \
  --format="value(name)")

echo "WIF_PROVIDER: $WIF_PROVIDER"
echo "WIF_SERVICE_ACCOUNT: $SA_EMAIL"
```

**Option B: Via Google Cloud Console**

1. **Get Provider Resource Name:**
   - Go to: https://console.cloud.google.com/iam-admin/workload-identity-pools?project=cognitech-infra-deployment
   - Click on **github-actions-pool**
   - Click on **github-provider**
   - Copy the **Provider resource name** (looks like):
     ```
     projects/123456789/locations/global/workloadIdentityPools/github-actions-pool/providers/github-provider
     ```

2. **Get Service Account Email:**
   - Already have it: `infra-deployer@cognitech-infra-deployment.iam.gserviceaccount.com`

---

## Step 4: Configure GitHub Repository Secrets

### 4.1 Add Secrets to GitHub

1. Go to your GitHub repository
2. Navigate to **Settings** → **Secrets and variables** → **Actions**
3. Click **New repository secret**

Add these two secrets:

| Secret Name | Value |
|------------|-------|
| `WIF_PROVIDER` | `projects/PROJECT_NUMBER/locations/global/workloadIdentityPools/github-actions-pool/providers/github-provider` |
| `WIF_SERVICE_ACCOUNT` | `infra-deployer@cognitech-infra-deployment.iam.gserviceaccount.com` |

**To get PROJECT_NUMBER:**
```bash
gcloud projects describe cognitech-infra-deployment --format="value(projectNumber)"
```

### 4.2 Verify Secrets

Your secrets should look like:
```
WIF_PROVIDER: projects/123456789/locations/global/workloadIdentityPools/github-actions-pool/providers/github-provider
WIF_SERVICE_ACCOUNT: infra-deployer@cognitech-infra-deployment.iam.gserviceaccount.com
```

---

## Step 5: Update Configuration Files

### 5.1 Update terraform.tfvars

Edit `deployments/int-production/shared-account/primary/terraform.tfvars`:

```bash
# Replace these values with your actual GCP resources
- organizations/123456789012    → Your organization ID
- 01234-56789A-BCDEF0          → Your billing account ID
- cognitech-prod-*              → Your project naming convention
- @cognitechllc.org            → Your domain
```

### 5.2 Update deployment-config.yaml

Edit `deployments/int-production/shared-account/primary/deployment-config.yaml`:

```yaml
serviceAccount: "infra-deployer@cognitech-infra-deployment.iam.gserviceaccount.com"
```

### 5.3 Update GitHub Workflow (Optional)

Edit `.github/workflows/deploy-infrastructure.yml` if needed:

```yaml
env:
  GCP_PROJECT_ID: "cognitech-infra-deployment"  # Update this
  DEPLOYMENT_LOCATION: "us-central1"             # Update region if needed
```

---

## Step 6: Deploy Using GitHub Actions

### Method 1: Automatic Deployment (Recommended)

#### 6.1 Create Feature Branch

```bash
git checkout -b feat/initial-infrastructure
```

#### 6.2 Make Changes (if needed)

Edit your configuration files as needed.

#### 6.3 Push and Create Pull Request

```bash
git add .
git commit -m "feat: Initial infrastructure configuration"
git push origin feat/initial-infrastructure
```

#### 6.4 Create PR in GitHub

1. Go to your GitHub repository
2. Click **Pull requests** → **New pull request**
3. Select your branch
4. Click **Create pull request**

#### 6.5 Review Preview

- GitHub Actions automatically runs
- Check the **Actions** tab for progress
- Review the Infrastructure Manager preview plan
- Preview shows what will be created/changed

#### 6.6 Merge to Deploy

- Once preview looks good, merge the PR
- GitHub Actions automatically deploys on merge to `main`
- Monitor deployment in **Actions** tab

### Method 2: Manual Trigger

#### 6.1 Go to Actions Tab

1. Navigate to **Actions** in your GitHub repository
2. Select **Deploy Infrastructure** workflow

#### 6.2 Run Workflow

1. Click **Run workflow** button
2. Select:
   - **Branch**: `main`
   - **Environment**: `int-production/shared-account/primary`
   - **Action**: `apply`
3. Click **Run workflow**

#### 6.3 Monitor Deployment

- Click on the running workflow
- Expand job steps to see progress
- View Terraform output in real-time

---

## Step 7: Verify Deployment

### 7.1 Check Infrastructure Manager Deployments

**Option A: Via gcloud CLI**

```bash
# List deployments
gcloud infra-manager deployments list \
  --location=us-central1 \
  --project=cognitech-infra-deployment

# Get deployment details
gcloud infra-manager deployments describe int-prod-shared-primary \
  --location=us-central1 \
  --project=cognitech-infra-deployment
```

**Option B: Via Google Cloud Console**

1. **View Infrastructure Manager Deployments:**
   - Go to: https://console.cloud.google.com/infrastructure-manager/deployments?project=cognitech-infra-deployment
   - Or: **Navigation Menu** (☰) → **Infrastructure Manager** → **Deployments**

2. **Check Deployment Status:**
   - Look for deployment: `int-prod-shared-primary`
   - **Status** should show: `ACTIVE` (green checkmark)
   - Click on deployment name to see details:
     - **Summary** tab: Shows deployment metadata
     - **Resources** tab: Lists all created resources
     - **Revisions** tab: Shows deployment history
     - **Terraform** tab: Shows state file

### 7.2 Verify Created Folders

**Option A: Via gcloud CLI**

```bash
# List folders
gcloud resource-manager folders list --organization=$ORG_ID

# View specific folder
gcloud resource-manager folders describe FOLDER_ID
```

**Option B: Via Google Cloud Console**

1. **View Organization Folders:**
   - Go to: https://console.cloud.google.com/cloud-resource-manager
   - Or: **Navigation Menu** (☰) → **IAM & Admin** → **Manage Resources**

2. **Verify Folder Structure:**
   - You should see folders:
     - `Production`
       - `Networking` (nested)
       - `Security` (nested)
     - `Shared Services`
       - `Monitoring` (nested)
   
3. **Click on each folder** to see nested folders and projects

### 7.3 Verify Created Projects

**Option A: Via gcloud CLI**

```bash
# List all projects
gcloud projects list

# List projects in a specific folder
gcloud projects list --filter="parent.id=FOLDER_ID"

# Get project details
gcloud projects describe PROJECT_ID
```

**Option B: Via Google Cloud Console**

1. **View All Projects:**
   - Go to: https://console.cloud.google.com/cloud-resource-manager
   - Or: Click **Project Dropdown** (top bar) → **ALL**

2. **Verify Projects Created:**
   - `cognitech-prod-network-hub` (under Production → Networking)
   - `cognitech-prod-spoke-1` (under Production → Networking)
   - `cognitech-prod-security-logs` (under Production → Security)
   - `cognitech-shared-monitoring` (under Shared Services → Monitoring)

3. **Check Project Details:**
   - Click on each project
   - Verify **APIs & Services** are enabled
   - Check **IAM & Admin** for service accounts and bindings

### 7.4 Verify Service Accounts and IAM Bindings

**Option A: Via gcloud CLI**

```bash
# List service accounts in a project
gcloud iam service-accounts list --project=PROJECT_ID

# List IAM bindings for a project
gcloud projects get-iam-policy PROJECT_ID

# List IAM bindings for a folder
gcloud resource-manager folders get-iam-policy FOLDER_ID
```

**Option B: Via Google Cloud Console**

1. **Check Service Accounts:**
   - Navigate to each project
   - **Navigation Menu** (☰) → **IAM & Admin** → **Service Accounts**
   - Verify service accounts are created

2. **Check IAM Bindings:**
   - **Navigation Menu** (☰) → **IAM & Admin** → **IAM**
   - Verify roles are assigned to users/groups/service accounts
   - Check both project-level and folder-level permissions

### 7.5 Verify Enabled APIs

**Option A: Via gcloud CLI**

```bash
# List enabled services in a project
gcloud services list --enabled --project=PROJECT_ID
```

**Option B: Via Google Cloud Console**

1. **Check Enabled APIs:**
   - Navigate to project
   - Go to: https://console.cloud.google.com/apis/dashboard?project=PROJECT_ID
   - Or: **Navigation Menu** (☰) → **APIs & Services** → **Dashboard**
   - Verify required APIs are enabled (Compute, Container, etc.)

---

## 🔄 Day-to-Day Operations

### Making Infrastructure Changes

**Standard Process:**

1. **Create feature branch**
   
   **Option A: Via CLI**
   ```bash
   git checkout -b feat/add-new-project
   ```
   
   **Option B: Via GitHub Web**
   - Go to your repository on GitHub
   - Click **Code** tab → Branch dropdown → **Create branch**
   - Name: `feat/add-new-project`

2. **Update terraform.tfvars**
   
   **Option A: Via CLI**
   ```bash
   # Edit locally
   vim deployments/int-production/shared-account/primary/terraform.tfvars
   ```
   
   **Option B: Via GitHub Web**
   - Navigate to the file on GitHub
   - Click the pencil icon (✏️) to edit
   - Make changes directly in browser

3. **Commit and push**
   
   **Option A: Via CLI**
   ```bash
   git add .
   git commit -m "feat: Add new monitoring project"
   git push origin feat/add-new-project
   ```
   
   **Option B: Via GitHub Web**
   - After editing, scroll down
   - Enter commit message: `feat: Add new monitoring project`
   - Select **Create a new branch** and start PR
   - Click **Propose changes**

4. **Create PR** → GitHub Actions runs preview automatically
   - Go to **Pull requests** tab
   - Click **New pull request** (if not created in step 3)
   - Select your branch and create PR
   - Actions will run automatically

5. **Review preview**
   - Click on **Actions** tab in PR
   - Expand job steps to see Terraform plan
   - Review what will be created/modified/destroyed

6. **Merge PR** → GitHub Actions deploys automatically
   - Click **Merge pull request**
   - Confirm merge
   - Watch **Actions** tab for deployment progress

### Emergency Rollback

**Option A: Via Git CLI**

```bash
# Option 1: Revert the commit
git revert HEAD
git push origin main

# Option 2: Reset to previous commit (dangerous!)
git reset --hard HEAD~1
git push --force origin main
```

**Option B: Via GitHub Web**

1. **Revert via GitHub:**
   - Go to **Commits** tab
   - Find the problematic commit
   - Click **⋯** → **Revert**
   - Merge the revert PR

2. **Manual workflow with previous version:**
   - Go to **Actions** → **Deploy Infrastructure**
   - Click **Run workflow**
   - Select previous commit/tag
   - Choose action: `apply`

### Destroying Resources (Use with Caution!)

**Via GitHub Actions:**

1. Go to **Actions** → **Deploy Infrastructure**
2. Click **Run workflow**
3. **Branch**: `main`
4. **Action**: `destroy`
5. **Confirm** and run
6. Monitor progress in Actions logs
7. Verify in GCP Infrastructure Manager console

---

## 🛠️ Alternative Deployment: Local Development & Testing

### Prerequisites

**Option A: Via gcloud CLI**

```bash
# Authenticate
gcloud auth login
gcloud config set project cognitech-infra-deployment

# Authenticate as service account (for production-like testing)
gcloud auth activate-service-account \
  --key-file=/path/to/service-account-key.json
```

**Option B: Via Google Cloud Console**

1. **Authenticate via Browser:**
   - Run `gcloud auth login` (opens browser automatically)
   - Or use **Cloud Shell** in Google Cloud Console:
     - Go to: https://console.cloud.google.com
     - Click **Activate Cloud Shell** (icon at top right)
     - Already authenticated with your account

2. **Set Project in Cloud Shell:**
   ```bash
   gcloud config set project cognitech-infra-deployment
   ```

### Preview Changes Locally

**Option A: Via gcloud CLI**

```bash
cd deployments/int-production/shared-account/primary

gcloud infra-manager previews create preview-local-$(date +%s) \
  --location=us-central1 \
  --deployment=projects/cognitech-infra-deployment/locations/us-central1/deployments/int-prod-shared-primary \
  --local-source="." \
  --project=cognitech-infra-deployment
```

**Option B: Via Cloud Shell + Console**

1. **Upload Code to Cloud Shell:**
   - Open Cloud Shell: https://console.cloud.google.com
   - Click **⋮** → **Upload file/folder**
   - Upload your deployment directory

2. **Run Preview:**
   ```bash
   cd deployments/int-production/shared-account/primary
   
   gcloud infra-manager previews create preview-local-$(date +%s) \
     --location=us-central1 \
     --deployment=projects/cognitech-infra-deployment/locations/us-central1/deployments/int-prod-shared-primary \
     --local-source="." \
     --project=cognitech-infra-deployment
   ```

3. **View Preview Results:**
   - Go to: https://console.cloud.google.com/infrastructure-manager/previews?project=cognitech-infra-deployment
   - Click on your preview to see planned changes

### Apply Changes Locally

**Option A: Via gcloud CLI**

```bash
gcloud infra-manager deployments apply \
  projects/cognitech-infra-deployment/locations/us-central1/deployments/int-prod-shared-primary \
  --location=us-central1 \
  --local-source="." \
  --project=cognitech-infra-deployment
```

**Option B: Via Cloud Shell**

1. **Run Apply in Cloud Shell:**
   ```bash
   gcloud infra-manager deployments apply \
     projects/cognitech-infra-deployment/locations/us-central1/deployments/int-prod-shared-primary \
     --location=us-central1 \
     --local-source="." \
     --project=cognitech-infra-deployment
   ```

2. **Monitor in Console:**
   - Go to: https://console.cloud.google.com/infrastructure-manager/deployments?project=cognitech-infra-deployment
   - Watch deployment progress in real-time

### Check Deployment Status

**Option A: Via gcloud CLI**

```bash
gcloud infra-manager deployments describe int-prod-shared-primary \
  --location=us-central1 \
  --project=cognitech-infra-deployment
```

**Option B: Via Google Cloud Console**

1. **View Deployment Details:**
   - Go to: https://console.cloud.google.com/infrastructure-manager/deployments?project=cognitech-infra-deployment
   - Click on `int-prod-shared-primary`
   - View **Summary**, **Resources**, **Revisions**, **Terraform** tabs

---

## 📊 Monitoring & Observability

### Infrastructure Manager Dashboard

**Option A: Via gcloud CLI**

```bash
# List all deployments
gcloud infra-manager deployments list \
  --location=us-central1 \
  --project=cognitech-infra-deployment

# Get deployment details with full output
gcloud infra-manager deployments describe int-prod-shared-primary \
  --location=us-central1 \
  --project=cognitech-infra-deployment \
  --format=yaml

# View deployment state
gcloud infra-manager deployments export-statefile int-prod-shared-primary \
  --location=us-central1 \
  --project=cognitech-infra-deployment

# View deployment revisions
gcloud infra-manager revisions list \
  --deployment=int-prod-shared-primary \
  --location=us-central1 \
  --project=cognitech-infra-deployment
```

**Option B: Via Google Cloud Console**

1. **Infrastructure Manager Dashboard:**
   - Go to: https://console.cloud.google.com/infrastructure-manager/deployments?project=cognitech-infra-deployment
   - Or: **Navigation Menu** (☰) → **Infrastructure Manager** → **Deployments**

2. **View Deployment Details:**
   - Click on deployment: `int-prod-shared-primary`
   - **Summary** tab:
     - Status (Active/Failed/Creating)
     - Deployment location
     - Service account used
     - Creation/update timestamps
   - **Resources** tab:
     - List of all managed resources
     - Resource types and names
     - Resource status
   - **Revisions** tab:
     - Deployment history
     - Each apply/update shown as revision
     - Terraform state per revision
   - **Terraform** tab:
     - View Terraform state file
     - Download state for troubleshooting

3. **View Deployment Logs:**
   - In deployment detail page, click **Logs** (if available)
   - Or go to: https://console.cloud.google.com/logs/query?project=cognitech-infra-deployment
   - Filter by:
     ```
     resource.type="config.googleapis.com/Deployment"
     resource.labels.deployment_name="int-prod-shared-primary"
     ```

### GitHub Actions Monitoring

**Via GitHub Web Interface:**

1. **View Workflow Runs:**
   - Go to your repository
   - Click **Actions** tab
   - See all workflow runs with status badges

2. **View Specific Run:**
   - Click on a workflow run
   - View **Summary** page:
     - Overall status
     - Duration
     - Triggered by (user/PR)
     - Annotations (errors/warnings)
   
3. **View Job Logs:**
   - Click on job name (e.g., "terraform-preview", "terraform-apply")
   - Expand each step to see detailed logs:
     - Authentication
     - Terraform init
     - Terraform plan/apply
     - Infrastructure Manager commands
   
4. **Monitor Real-time:**
   - When workflow is running, logs update in real-time
   - Yellow indicator = in progress
   - Green checkmark = success
   - Red X = failure

### Cloud Monitoring Integration (Optional)

**Option A: Via gcloud CLI**

```bash
# Create alert policy for deployment failures
gcloud alpha monitoring policies create \
  --notification-channels=CHANNEL_ID \
  --display-name="Infra Manager Deployment Failed" \
  --condition-display-name="Deployment Failure" \
  --condition-threshold-value=1 \
  --condition-threshold-duration=60s
```

**Option B: Via Google Cloud Console**

1. **Set up Monitoring Dashboard:**
   - Go to: https://console.cloud.google.com/monitoring?project=cognitech-infra-deployment
   - Or: **Navigation Menu** (☰) → **Monitoring** → **Dashboards**
   - Click **+ CREATE DASHBOARD**
   - Add charts for:
     - Deployment success rate
     - Deployment duration
     - Resource count

2. **Create Alert Policies:**
   - Go to: https://console.cloud.google.com/monitoring/alerting?project=cognitech-infra-deployment
   - Or: **Navigation Menu** (☰) → **Monitoring** → **Alerting**
   - Click **+ CREATE POLICY**
   - Configure alert for deployment failures
   - Add notification channels (email, Slack, PagerDuty)

3. **View Logs Explorer:**
   - Go to: https://console.cloud.google.com/logs/query?project=cognitech-infra-deployment
   - Query Infrastructure Manager logs:
     ```
     resource.type="config.googleapis.com/Deployment"
     severity>=ERROR
     ```

---

## 🔧 Customization Guide

### Adding a New Environment

**Example: Create staging environment**

1. **Create directory structure**
   ```bash
   mkdir -p deployments/staging/network-account/primary
   cd deployments/staging/network-account/primary
   ```

2. **Copy configuration files**
   ```bash
   cp ../../../../int-production/shared-account/primary/*.tf .
   cp ../../../../int-production/shared-account/primary/deployment-config.yaml .
   ```

3. **Update terraform.tfvars**
   ```hcl
   # Use staging-specific values
   org = {
     folders = {
       "staging" = {
         display_name = "Staging"
         parent       = "organizations/123456789012"
       }
     }
     # ... staging projects
   }
   ```

4. **Update deployment-config.yaml**
   ```yaml
   name: projects/cognitech-infra-deployment/locations/us-central1/deployments/staging-network-primary
   labels:
     environment: staging
   ```

5. **Update GitHub workflow** (optional)
   ```yaml
   # Add to workflow_dispatch options
   options:
     - int-production/shared-account/primary
     - staging/network-account/primary
   ```

### Adding New Projects

Edit `terraform.tfvars`:

```hcl
org = {
  projects = {
    # Existing projects...
    
    # Add new project
    "new-app" = {
      name         = "cognitech-prod-new-app"
      project_id   = "cognitech-prod-new-app"
      folder_key   = "production"  # Parent folder
      billing_key  = "default"
      
      enabled_services = [
        "compute.googleapis.com",
        "container.googleapis.com"
      ]
      
      labels = {
        environment = "production"
        team        = "platform"
        app         = "new-app"
      }
    }
  }
}
```

### Adding Service Accounts

```hcl
iam = {
  service_accounts = {
    # Existing service accounts...
    
    # Add new service account
    "new-app-sa" = {
      account_id   = "new-app-automation"
      display_name = "New App Automation Service Account"
      description  = "Service account for new app automation"
      project_key  = "new-app"  # References project above
    }
  }
}
```

### Module Version Updates

In `main.tf`, update module versions:

```hcl
module "org" {
  source = "git::https://github.com/KahBrightTech/Cognitech-GCP-Infrastructure-Manager-repo.git//Infrastructure-Manger/modules/Org?ref=v2.0.0"
  # Changed from v1.0.0 to v2.0.0
  # ...
}
```

---

## 📝 Best Practices

### General Guidelines

✅ **DO:**
- Always preview changes before applying
- Use pull requests for all changes
- Pin module versions with git tags (`?ref=v1.0.0`)
- Test in lower environments first (dev → staging → production)
- Use meaningful commit messages (`feat:`, `fix:`, `chore:`)
- Add labels to all resources for cost tracking
- Document all major changes in PR descriptions
- Keep terraform.tfvars in sync with actual infrastructure

❌ **DON'T:**
- Never commit sensitive data (keys, passwords)
- Don't bypass PR process for production
- Avoid manual changes in GCP console (infrastructure drift)
- Don't use `latest` or untagged module versions in production
- Never run `destroy` without extreme caution

### Security Best Practices

1. **Use Workload Identity Federation** (no service account keys!)
2. **Principle of Least Privilege** - Grant minimum required permissions
3. **Enable audit logging** - Track all infrastructure changes
4. **Use separate service accounts** per environment
5. **Rotate credentials** regularly
6. **Enable organization policies** for security guardrails

### Cost Optimization

1. **Use labels consistently** for cost allocation
2. **Enable budget alerts** in billing project
3. **Review resource usage** monthly
4. **Delete unused resources** promptly
5. **Use committed use discounts** for stable workloads

---

## 🔐 Required Permissions Summary

### Service Account Permissions

The `infra-deployer` service account needs these roles:

| Scope | Role | Purpose |
|-------|------|---------|
| **Organization** | `roles/resourcemanager.folderCreator` | Create folders |
| **Organization** | `roles/resourcemanager.projectCreator` | Create projects |
| **Organization** | `roles/iam.organizationRoleAdmin` | Manage custom roles |
| **Organization** | `roles/billing.user` | Link billing accounts |
| **Organization** | `roles/config.agent` | Infrastructure Manager operations |
| **Project** | `roles/iam.serviceAccountAdmin` | Create service accounts |
| **Project** | `roles/serviceusage.serviceUsageAdmin` | Enable APIs |

### GitHub Actions Permissions

The GitHub Actions workflow needs:

- **Workload Identity Pool** access
- **Service Account Impersonation** (`roles/iam.workloadIdentityUser`)

---

## 🆘 Troubleshooting

### Common Issues and Solutions

#### Issue 1: GitHub Actions Authentication Failed

**Error:**
```
Error: google-github-actions/auth failed with: retry function failed after 4 attempts
```

**Solution:**

**Option A: Via gcloud CLI**

```bash
# Verify WIF configuration
gcloud iam service-accounts describe $SA_EMAIL

# Verify repository attribute condition
gcloud iam workload-identity-pools providers describe github-provider \
  --project="cognitech-infra-deployment" \
  --location="global" \
  --workload-identity-pool="github-actions-pool"

# Check service account IAM bindings
gcloud iam service-accounts get-iam-policy $SA_EMAIL
```

**Option B: Via Google Cloud Console**

1. **Verify Workload Identity Federation:**
   - Go to: https://console.cloud.google.com/iam-admin/workload-identity-pools?project=cognitech-infra-deployment
   - Click **github-actions-pool** → **github-provider**
   - Verify **Attribute Conditions** match your GitHub org/repo
   - Check **Issuer** is `https://token.actions.githubusercontent.com`

2. **Verify Service Account Permissions:**
   - Go to: https://console.cloud.google.com/iam-admin/serviceaccounts?project=cognitech-infra-deployment
   - Click **infra-deployer** service account
   - Click **PERMISSIONS** tab
   - Verify `Workload Identity User` role is granted to:
     ```
     principalSet://iam.googleapis.com/projects/PROJECT_NUMBER/locations/global/workloadIdentityPools/github-actions-pool/attribute.repository/YOUR_ORG/YOUR_REPO
     ```

3. **Verify GitHub Secrets:**
   - Go to your GitHub repository
   - **Settings** → **Secrets and variables** → **Actions**
   - Verify:
     - `WIF_PROVIDER` matches provider resource name
     - `WIF_SERVICE_ACCOUNT` matches service account email

#### Issue 2: Permission Denied Errors

**Error:**
```
Error: Error creating Folder: googleapi: Error 403: Permission denied on resource
```

**Solution:**

**Option A: Via gcloud CLI**

```bash
# Grant missing permissions
gcloud organizations add-iam-policy-binding $ORG_ID \
  --member="serviceAccount:$SA_EMAIL" \
  --role="roles/resourcemanager.folderCreator"

# Verify permissions were granted
gcloud organizations get-iam-policy $ORG_ID \
  --flatten="bindings[].members" \
  --filter="bindings.members:serviceAccount:$SA_EMAIL"

# Wait 60-120 seconds for IAM propagation
# Then retry deployment
```

**Option B: Via Google Cloud Console**

1. **Grant Organization-Level Permissions:**
   - Go to: https://console.cloud.google.com/iam-admin/iam
   - Select your **Organization** (at the top)
   - Click **GRANT ACCESS**
   - **Principal**: `infra-deployer@cognitech-infra-deployment.iam.gserviceaccount.com`
   - **Role**: Add missing role (e.g., `Folder Creator`)
   - Click **SAVE**

2. **Wait for IAM Propagation:**
   - Wait 60-120 seconds
   - IAM changes can take time to propagate globally

3. **Retry Deployment:**
   - Go to GitHub repository → **Actions** tab
   - Click **Re-run all jobs** on failed workflow

#### Issue 3: Deployment Stuck in CREATING State

**Solution:**

**Option A: Via gcloud CLI**

```bash
# Check deployment status
gcloud infra-manager deployments describe int-prod-shared-primary \
  --location=us-central1 \
  --project=cognitech-infra-deployment

# If truly stuck (>30 minutes), delete and recreate
gcloud infra-manager deployments delete int-prod-shared-primary \
  --location=us-central1 \
  --project=cognitech-infra-deployment \
  --delete-policy=DELETE

# Then redeploy via GitHub Actions
```

**Option B: Via Google Cloud Console**

1. **Check Deployment Status:**
   - Go to: https://console.cloud.google.com/infrastructure-manager/deployments?project=cognitech-infra-deployment
   - Click on `int-prod-shared-primary`
   - Check **Status** and **Latest Revision**
   - View **Logs** for error messages

2. **If Stuck (>30 minutes), Delete Deployment:**
   - Click **DELETE** button at the top
   - **Delete policy**: `Delete all resources`
   - Confirm deletion

3. **Redeploy:**
   - Go to GitHub repository → **Actions** tab
   - Click **Deploy Infrastructure** workflow
   - Click **Run workflow**
   - Select **action**: `apply`

#### Issue 4: Module Not Found

**Error:**
```
Error: Failed to download module
Could not download module "iam" source
```

**Solution:**

**Option A: Via gcloud CLI / Git**

```bash
# Verify git URL in main.tf is correct
cat deployments/*/main.tf | grep "source = "

# Test module URL manually
git ls-remote https://github.com/KahBrightTech/Cognitech-GCP-Infrastructure-Manager-repo.git

# Check the git ref/tag exists
git ls-remote --tags https://github.com/KahBrightTech/Cognitech-GCP-Infrastructure-Manager-repo.git | grep v1.0.0

# Verify module path exists
git clone https://github.com/KahBrightTech/Cognitech-GCP-Infrastructure-Manager-repo.git temp
ls -la temp/Infrastructure-Manger/modules/
```

**Option B: Via GitHub Web**

1. **Verify Module Repository:**
   - Go to: https://github.com/KahBrightTech/Cognitech-GCP-Infrastructure-Manager-repo
   - Verify repository is accessible (public or you have access)

2. **Check Module Path:**
   - Navigate to: **Infrastructure-Manger** → **modules**
   - Verify the module exists (e.g., `IAM`, `Org`)

3. **Check Git Tag/Ref:**
   - Click **Tags** dropdown (near branches)
   - Verify the tag referenced in your code exists (e.g., `v1.0.0`)

4. **Fix in Your Code:**
   - Update [main.tf](deployments/int-production/shared-account/primary/main.tf) with correct:
     - Repository URL
     - Module path
     - Git ref/tag
   - Commit and push changes
git ls-remote https://github.com/KahBrightTech/Cognitech-GCP-Infrastructure-Manager-repo.git v1.0.0
```

#### Issue 5: Billing Account Not Linked

**Error:**
```
Error: Error setting billing account: googleapi: Error 400: Precondition check failed
```

**Solution:**

**Option A: Via gcloud CLI**

```bash
# Verify billing account ID
gcloud billing accounts list

# Grant billing.user role at organization level
gcloud organizations add-iam-policy-binding $ORG_ID \
  --member="serviceAccount:$SA_EMAIL" \
  --role="roles/billing.user"

# Or at billing account level
gcloud billing accounts add-iam-policy-binding BILLING_ACCOUNT_ID \
  --member="serviceAccount:$SA_EMAIL" \
  --role="roles/billing.user"

# Verify binding
gcloud billing accounts get-iam-policy BILLING_ACCOUNT_ID
```

**Option B: Via Google Cloud Console**

1. **Grant Billing Permissions:**
   - Go to: https://console.cloud.google.com/billing
   - Click on your **Billing Account**
   - Click **Account Management** (left sidebar)
   - Click **ADD PRINCIPAL**
   - **Principal**: `infra-deployer@cognitech-infra-deployment.iam.gserviceaccount.com`
   - **Role**: `Billing Account User`
   - Click **SAVE**

2. **Verify Billing Account ID:**
   - On billing page, copy **Billing Account ID** (format: `01234A-5678BC-9012DE`)
   - Update in your terraform.tfvars if needed

3. **Retry Deployment:**
   - GitHub Actions → Re-run failed workflow

#### Issue 6: Terraform State Locked

**Error:**
```
Error: Error acquiring the state lock
```

**Solution:**

**Note:** Infrastructure Manager handles state automatically. State locks usually resolve automatically.

**Option A: Via gcloud CLI**

```bash
# Check current deployment status
gcloud infra-manager deployments describe int-prod-shared-primary \
  --location=us-central1 \
  --project=cognitech-infra-deployment

# If truly stuck (rare), delete and recreate deployment
gcloud infra-manager deployments delete int-prod-shared-primary \
  --location=us-central1 \
  --project=cognitech-infra-deployment \
  --delete-policy=ABANDON  # Keeps resources, removes deployment only
```

**Option B: Via Google Cloud Console**

1. **Check Deployment Status:**
   - Go to: https://console.cloud.google.com/infrastructure-manager/deployments?project=cognitech-infra-deployment
   - Click `int-prod-shared-primary`
   - Check if another operation is in progress
   - Wait for it to complete

2. **If Genuinely Stuck:**
   - Click **DELETE** (top of page)
   - **Delete policy**: `Abandon resources` (safer - keeps resources)
   - Confirm

3. **Recreate Deployment:**
   - GitHub Actions → Deploy Infrastructure → Run workflow → action: `apply`

#### Issue 7: Organization Policy Violations

**Error:**
```
Error: Request violates constraint: constraints/iam.disableServiceAccountKeyCreation
```

**Solution:**

**Option A: Via gcloud CLI**

```bash
# View the organization policy
gcloud resource-manager org-policies describe \
  constraints/iam.disableServiceAccountKeyCreation \
  --organization=$ORG_ID

# List all org policies (to find conflicting ones)
gcloud resource-manager org-policies list \
  --organization=$ORG_ID

# Option 1: Remove violating resource from Terraform config
# Option 2: Update policy if you're an admin
# Option 3: Request exception from org admin
```

**Option B: Via Google Cloud Console**

1. **View Organization Policies:**
   - Go to: https://console.cloud.google.com/iam-admin/orgpolicies
   - Select your **Organization** at the top
   - Search for the constraint mentioned in error (e.g., `iam.disableServiceAccountKeyCreation`)

2. **Review Policy Details:**
   - Click on the policy constraint
   - See if it's **Enforced** or has specific rules
   - Check what resources are affected

3. **Solutions:**
   
   **Option 1: Remove Violating Resource**
   - Update your Terraform code to remove the resource causing the violation
   - Example: If policy blocks service account keys, don't create keys
   
   **Option 2: Request Policy Exception (if applicable)**
   - Contact your Organization Admin
   - Request exemption for your project/folder
   
   **Option 3: Modify Policy (if you're admin)**
   - Click **EDIT POLICY**
   - Add exception for your project/service account
   - Click **SAVE**

### Debugging Tips

#### Enable Detailed Logging in GitHub Actions

In your workflow ([.github/workflows/deploy-infrastructure.yml](.github/workflows/deploy-infrastructure.yml)), add:

```yaml
- name: Apply Infrastructure
  env:
    TF_LOG: DEBUG          # Enable Terraform debug logging
    TF_LOG_PATH: tf.log    # Write logs to file
  run: |
    # Your deployment command
```

#### Check Infrastructure Manager Logs

**Option A: Via gcloud CLI**

```bash
# Export full deployment details
gcloud infra-manager deployments describe int-prod-shared-primary \
  --location=us-central1 \
  --project=cognitech-infra-deployment \
  --format=json > deployment-debug.json

# Check error messages
cat deployment-debug.json | jq '.error'

# View latest revision logs
gcloud infra-manager revisions describe REVISION_ID \
  --deployment=int-prod-shared-primary \
  --location=us-central1 \
  --project=cognitech-infra-deployment

# Query Cloud Logging
gcloud logging read "resource.type=config.googleapis.com/Deployment" \
  --project=cognitech-infra-deployment \
  --limit=50 \
  --format=json
```

**Option B: Via Google Cloud Console**

1. **View Deployment Logs:**
   - Go to: https://console.cloud.google.com/infrastructure-manager/deployments?project=cognitech-infra-deployment
   - Click on `int-prod-shared-primary`
   - **Revisions** tab → Click latest revision
   - View **Error message** if deployment failed

2. **Query Logs Explorer:**
   - Go to: https://console.cloud.google.com/logs/query?project=cognitech-infra-deployment
   - Or: **Navigation Menu** (☰) → **Logging** → **Logs Explorer**
   - Use query:
     ```
     resource.type="config.googleapis.com/Deployment"
     resource.labels.deployment_name="int-prod-shared-primary"
     severity>=ERROR
     ```
   - Click **Run Query**
   - Expand log entries to see full error details

3. **Download Terraform State (for advanced debugging):**
   - In deployment details page → **Terraform** tab
   - Click **Download state** to analyze locally

#### Validate Configuration Locally

**Option A: Via Local Terraform CLI**

```bash
cd deployments/int-production/shared-account/primary

# Initialize Terraform
terraform init

# Validate syntax
terraform validate

# Check formatting
terraform fmt -check

# Format check
terraform fmt -check -recursive
```

**Option B: Via Cloud Shell**

1. **Open Cloud Shell:**
   - Go to: https://console.cloud.google.com
   - Click **Activate Cloud Shell** (top right)

2. **Upload and Validate:**
   - Upload your deployment directory
   - Run validation:
     ```bash
     cd deployments/int-production/shared-account/primary
     terraform init
     terraform validate
     ```

#### Test Service Account Impersonation

**Option A: Via gcloud CLI**

```bash
# Test if you can impersonate the service account locally
gcloud auth application-default print-access-token \
  --impersonate-service-account=$SA_EMAIL

# Or test via explicit impersonation
gcloud projects list --impersonate-service-account=$SA_EMAIL
```

**Option B: Via Google Cloud Console**

1. **Check Service Account Permissions:**
   - Go to: https://console.cloud.google.com/iam-admin/serviceaccounts?project=cognitech-infra-deployment
   - Click **infra-deployer** service account
   - **PERMISSIONS** tab shows who can impersonate it

2. **Test in Cloud Shell (as your user):**
   ```bash
   # Try to impersonate from Cloud Shell
   gcloud auth print-access-token \
     --impersonate-service-account=infra-deployer@cognitech-infra-deployment.iam.gserviceaccount.com
   ```

3. **Verify in IAM:**
   - Service account should have `roles/iam.serviceAccountTokenCreator` granted to:
     - Your user (for local testing)
     - Workload Identity Pool principal (for GitHub Actions)

### Getting Help

If you're still stuck:

1. **Check GCP Status**: https://status.cloud.google.com
2. **Review Audit Logs**: https://console.cloud.google.com/logs
3. **GitHub Issues**: [Create an issue](https://github.com/KahBrightTech/Cognitech-GCP-Network-repo/issues)
4. **Internal Support**: platform-team@cognitechllc.org

---

## 📚 References & Documentation

### Google Cloud Documentation
- [Infrastructure Manager Overview](https://cloud.google.com/infrastructure-manager/docs/overview)
- [Workload Identity Federation](https://cloud.google.com/iam/docs/workload-identity-federation)
- [Infrastructure Manager Best Practices](https://cloud.google.com/infrastructure-manager/docs/best-practices)
- [Terraform Google Provider](https://registry.terraform.io/providers/hashicorp/google/latest/docs)

### GitHub Documentation
- [GitHub Actions Workflow Syntax](https://docs.github.com/en/actions/using-workflows/workflow-syntax-for-github-actions)
- [Encrypted Secrets](https://docs.github.com/en/actions/security-guides/encrypted-secrets)
- [OIDC with GCP](https://docs.github.com/en/actions/deployment/security-hardening-your-deployments/configuring-openid-connect-in-google-cloud-platform)

### Related Repositories
- [Infrastructure Manager Modules Repository](https://github.com/KahBrightTech/Cognitech-GCP-Infrastructure-Manager-repo)

### Command Reference Quick Links

**Infrastructure Manager:**
```bash
# Comprehensive command reference
gcloud infra-manager --help
gcloud infra-manager deployments --help
gcloud infra-manager previews --help
```

**IAM:**
```bash
# IAM command reference
gcloud iam --help
gcloud iam service-accounts --help
gcloud iam workload-identity-pools --help
```

---

## 🏁 Quick Start Checklist

Use this checklist when setting up a new deployment:

- [ ] **Step 1: GCP Setup**
  - [ ] Create deployment project
  - [ ] Enable required APIs
  - [ ] Configure billing

- [ ] **Step 2: Service Account**
  - [ ] Create infra-deployer service account
  - [ ] Grant organization permissions
  - [ ] Grant project permissions

- [ ] **Step 3: Workload Identity**
  - [ ] Create workload identity pool
  - [ ] Create GitHub OIDC provider
  - [ ] Link service account to GitHub repo

- [ ] **Step 4: GitHub Configuration**
  - [ ] Add WIF_PROVIDER secret
  - [ ] Add WIF_SERVICE_ACCOUNT secret
  - [ ] Verify secrets are correct

- [ ] **Step 5: Configuration Files**
  - [ ] Update terraform.tfvars with your values
  - [ ] Update deployment-config.yaml
  - [ ] Update GitHub workflow (if needed)

- [ ] **Step 6: Test Deployment**
  - [ ] Create feature branch
  - [ ] Create PR to trigger preview
  - [ ] Review preview output
  - [ ] Merge to deploy

- [ ] **Step 7: Verification**
  - [ ] Check GCP console for resources
  - [ ] Verify folders created
  - [ ] Verify projects created
  - [ ] Verify IAM bindings

---

## 📞 Support & Contributing

### Getting Support

**Priority Issues:**
- Security vulnerabilities: security@cognitechllc.org
- Production outages: Slack #infrastructure-alerts

**General Questions:**
- GitHub Discussions: [Start a discussion](https://github.com/KahBrightTech/Cognitech-GCP-Network-repo/discussions)
- Internal Slack: #infrastructure-help
- Email: platform-team@cognitechllc.org

### Contributing

We welcome contributions! To contribute:

1. Fork the repository
2. Create a feature branch (`git checkout -b feat/amazing-feature`)
3. Make your changes
4. Test thoroughly in a non-production environment
5. Commit using conventional commits (`feat:`, `fix:`, `docs:`, etc.)
6. Push to your branch
7. Open a Pull Request

**Code Review Process:**
- All PRs require at least one approval
- Automated checks must pass
- Preview deployment must succeed
- Documentation must be updated

---

## 📄 License

Copyright © 2026 Cognitech LLC. All rights reserved.

This repository is proprietary and confidential. Unauthorized copying, modification, or distribution is prohibited.

---

## 📅 Changelog

### v1.0.0 (2026-05-22)
- Initial release
- GitHub Actions workflow for automated deployments
- Workload Identity Federation for secure authentication
- Terragrunt-inspired structure with formations and deployments
- Comprehensive documentation and troubleshooting guide

---

**Last Updated:** May 22, 2026
**Maintained By:** Cognitech Platform Team
**Documentation Version:** 1.0.0
