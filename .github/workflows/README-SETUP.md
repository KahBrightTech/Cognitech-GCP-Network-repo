# GitHub Actions Workflow Setup for GCP Infrastructure Manager

## Overview
This workflow automates GCP Infrastructure Manager deployments using GitHub Actions and Workload Identity Federation (keyless authentication).

### How Workload Identity Federation Works

```
┌─────────────────────┐
│  GitHub Actions     │
│  (Your Workflow)    │
└──────────┬──────────┘
           │ 1. Request OIDC token
           │    with repository claim
           ▼
┌─────────────────────┐
│  GitHub OIDC        │
│  Token Service      │
└──────────┬──────────┘
           │ 2. Returns signed JWT
           │    with repo identity
           ▼
┌─────────────────────┐
│  GCP Workload       │
│  Identity Pool      │◄──── You create this!
└──────────┬──────────┘
           │ 3. Validates token
           │    Maps attributes
           ▼
┌─────────────────────┐
│  Service Account    │◄──── infra-manager-sa
│  Impersonation      │
└──────────┬──────────┘
           │ 4. Gets temporary
           │    GCP credentials
           ▼
┌─────────────────────┐
│  Infrastructure     │
│  Manager API        │
└─────────────────────┘
```

**Benefits:**
- ✅ No service account keys stored in GitHub secrets
- ✅ Automatic credential rotation
- ✅ Repository-level security (only your repo can authenticate)
- ✅ Audit trail in GCP logs

## Prerequisites
1. GCP Project with Infrastructure Manager API enabled
2. Service Account with appropriate permissions
3. GitHub repository with proper access
4. Workload Identity Federation configured

## Quick Setup Checklist

Follow these steps to enable GitHub Actions to deploy your infrastructure:

- [ ] **Step 1:** Enable required GCP APIs (config, iam, cloudresourcemanager)
- [ ] **Step 2:** Create Workload Identity Pool named `github-pool`
- [ ] **Step 3:** Create OIDC Provider named `github-provider` with GitHub token endpoint
- [ ] **Step 4:** Configure attribute mappings (google.subject, attribute.repository, etc.)
- [ ] **Step 5:** Grant service account `infra-manager-sa` the Workload Identity User role for your GitHub repo
- [ ] **Step 6:** Copy the provider resource name and update workflow file
- [ ] **Step 7:** Create GitHub Environment `production` with required reviewers
- [ ] **Step 8:** Create GitHub Environment `production-destroy` with required reviewers
- [ ] **Step 9:** Verify service account has all necessary IAM roles
- [ ] **Step 10:** Test the workflow with a manual trigger

**Estimated Time:** 15-20 minutes (first time)

---

## Detailed Setup Instructions

### 1. Enable Required APIs

You need to enable three APIs for GitHub Actions to work with Infrastructure Manager.

#### Option A: Using GCP Console

1. Go to [GCP Console APIs & Services → Library](https://console.cloud.google.com/apis/library)
2. Select project: **dev-project-1430**
3. Search and enable each of these APIs:

   **a) Infrastructure Manager API**
   - Search: `Infrastructure Manager API` or `config.googleapis.com`
   - Click on the API → Click **"Enable"**

   **b) IAM Service Account Credentials API**
   - Search: `IAM Service Account Credentials API` or `iamcredentials.googleapis.com`
   - Click on the API → Click **"Enable"**

   **c) Cloud Resource Manager API**
   - Search: `Cloud Resource Manager API` or `cloudresourcemanager.googleapis.com`
   - Click on the API → Click **"Enable"**

4. Verify all three are enabled at [APIs & Services → Dashboard](https://console.cloud.google.com/apis/dashboard)

#### Option B: Using gcloud CLI

```bash
gcloud services enable config.googleapis.com \
  iamcredentials.googleapis.com \
  cloudresourcemanager.googleapis.com \
  --project=dev-project-1430
```

### 2. Create Workload Identity Pool and Provider

You can create the Workload Identity Pool and Provider using either the **GCP Console** (recommended for first-time setup) or **gcloud CLI**.

#### Option A: Using GCP Console (Recommended)

**Step 2a: Create Workload Identity Pool**

1. Go to [GCP Console IAM & Admin → Workload Identity Federation](https://console.cloud.google.com/iam-admin/workload-identity-pools)
2. Select project: **dev-project-1430**
3. Click **"Create Pool"**
4. Configure:
   - **Pool name:** `github-pool`
   - **Pool ID:** `github-pool` (auto-filled)
   - **Description:** `Workload Identity Pool for GitHub Actions`
   - **Pool enabled:** ✅ Checked
5. Click **"Continue"**

**Step 2b: Add OIDC Provider to Pool**

6. On the "Add a provider to pool" screen:
   - **Select a provider:** Choose **"OpenID Connect (OIDC)"**
   - **Provider name:** `github-provider`
   - **Provider ID:** `github-provider` (auto-filled)
7. Click **"Continue"**

**Step 2c: Configure Provider Settings**

8. Configure OIDC settings:
   - **Issuer (URL):** `https://token.actions.githubusercontent.com`
   - **Allowed audiences:** Leave as **"Default audience"**
9. Click **"Continue"**

**Step 2d: Configure Attribute Mapping**

10. Set attribute mappings (click "Add mapping" for each):

    **Mapping 1 (Required):**
    - **Google attribute:** `google.subject`
    - **Attribute value:** `assertion.sub`
    - **Purpose:** Unique identifier containing repo and branch info
    - **Example value:** `repo:KahBrightTech/Cognitech-GCP-Network-repo:ref:refs/heads/main`

    **Mapping 2 (Recommended):**
    - **Google attribute:** `attribute.actor`
    - **Attribute value:** `assertion.actor`
    - **Purpose:** GitHub username who triggered the workflow
    - **Example value:** `your-github-username`

    **Mapping 3 (Required for your workflow):**
    - **Google attribute:** `attribute.repository`
    - **Attribute value:** `assertion.repository`
    - **Purpose:** Full repository name used for authorization
    - **Example value:** `KahBrightTech/Cognitech-GCP-Network-repo`

    **Mapping 4 (Optional but useful):**
    - **Google attribute:** `attribute.repository_owner`
    - **Attribute value:** `assertion.repository_owner`
    - **Purpose:** Repository owner name
    - **Example value:** `KahBrightTech`

    **How to enter each mapping:**
    - Click **"Add mapping"** button
    - In the **first field (Google attribute)**, enter the left side (e.g., `google.subject`)
    - In the **second field (Attribute value)**, enter the right side (e.g., `assertion.sub`)
    - Click checkmark or press Enter to confirm
    - Repeat for all 4 mappings

    **What these mappings do:**
    These extract claims from GitHub's OIDC token and make them available to GCP for authorization. The `google.subject` is required by GCP. The `attribute.repository` is used in Step 3 to restrict which repository can authenticate.

11. Click **"Save"**

**Step 2e: Get the Workload Identity Provider Path**

12. After creation, click on **"github-provider"** in the pool
13. Copy the **"Provider resource name"** - it looks like:
    ```
    projects/PROJECT_NUMBER/locations/global/workloadIdentityPools/github-pool/providers/github-provider
    ```
14. Save this for Step 6 (updating workflow file)

#### Option B: Using gcloud CLI

```bash
# Set variables
export PROJECT_ID="dev-project-1430"
export PROJECT_NUMBER=$(gcloud projects describe $PROJECT_ID --format="value(projectNumber)")
export POOL_NAME="github-pool"
export PROVIDER_NAME="github-provider"
export REPO="KahBrightTech/Cognitech-GCP-Network-repo"

# Create Workload Identity Pool
gcloud iam workload-identity-pools create $POOL_NAME \
  --project="$PROJECT_ID" \
  --location="global" \
  --display-name="GitHub Actions Pool"

# Create Workload Identity Provider
gcloud iam workload-identity-pools providers create-oidc $PROVIDER_NAME \
  --project="$PROJECT_ID" \
  --location="global" \
  --workload-identity-pool="$POOL_NAME" \
  --display-name="GitHub Provider" \
  --attribute-mapping="google.subject=assertion.sub,attribute.actor=assertion.actor,attribute.repository=assertion.repository,attribute.repository_owner=assertion.repository_owner" \
  --issuer-uri="https://token.actions.githubusercontent.com"

# Get the provider path for Step 6
gcloud iam workload-identity-pools providers describe $PROVIDER_NAME \
  --project="$PROJECT_ID" \
  --location="global" \
  --workload-identity-pool="$POOL_NAME" \
  --format="value(name)"
```

### 3. Grant Service Account Access to Workload Identity

This step allows your GitHub repository to authenticate as the service account.

#### Option A: Using GCP Console

1. Go to [IAM & Admin → Service Accounts](https://console.cloud.google.com/iam-admin/serviceaccounts)
2. Select project: **dev-project-1430**
3. Find and click on **infra-manager-sa@dev-project-1430.iam.gserviceaccount.com**
4. Click the **"Permissions"** tab
5. Click **"Grant Access"**
6. In the "Add principals" field, enter:
   ```
   principalSet://iam.googleapis.com/projects/PROJECT_NUMBER/locations/global/workloadIdentityPools/github-pool/attribute.repository/KahBrightTech/Cognitech-GCP-Network-repo
   ```
   **⚠️ Important:** Replace `PROJECT_NUMBER` with your actual project number. Find it by:
   - Go to [GCP Console Home](https://console.cloud.google.com/home/dashboard)
   - Look for **"Project number"** under project info
   - Or run: `gcloud projects describe dev-project-1430 --format="value(projectNumber)"`

7. Select role: **Workload Identity User** (`roles/iam.workloadIdentityUser`)
8. Click **"Save"**

#### Option B: Using gcloud CLI

```bash
# Get your project number
export PROJECT_ID="dev-project-1430"
export PROJECT_NUMBER=$(gcloud projects describe $PROJECT_ID --format="value(projectNumber)")
export POOL_NAME="github-pool"
export REPO="KahBrightTech/Cognitech-GCP-Network-repo"

# Allow GitHub Actions from your repo to impersonate the service account
gcloud iam service-accounts add-iam-policy-binding \
  infra-manager-sa@dev-project-1430.iam.gserviceaccount.com \
  --project="$PROJECT_ID" \
  --role="roles/iam.workloadIdentityUser" \
  --member="principalSet://iam.googleapis.com/projects/$PROJECT_NUMBER/locations/global/workloadIdentityPools/$POOL_NAME/attribute.repository/$REPO"
```

### 4. Update Workflow File

You need to update the `WORKLOAD_IDENTITY_PROVIDER` environment variable in your workflow file with the actual provider path.

#### Get Your Provider Path

**Option A: From GCP Console**

1. Go to [IAM & Admin → Workload Identity Federation](https://console.cloud.google.com/iam-admin/workload-identity-pools)
2. Select project: **dev-project-1430**
3. Click on **"github-pool"**
4. Click on **"github-provider"**
5. Copy the **"Provider resource name"** at the top of the page
   - It looks like: `projects/123456789/locations/global/workloadIdentityPools/github-pool/providers/github-provider`

**Option B: Using gcloud CLI**

```bash
gcloud iam workload-identity-pools providers describe github-provider \
  --project="dev-project-1430" \
  --location="global" \
  --workload-identity-pool="github-pool" \
  --format="value(name)"
```

#### Update the Workflow

1. Open [.github/workflows/deploy-playground-dev-project.yaml](.github/workflows/deploy-playground-dev-project.yaml)
2. Find the `WORKLOAD_IDENTITY_PROVIDER` line (around line 10)
3. Replace it with your actual provider path:

```yaml
env:
  GCP_PROJECT_ID: "dev-project-1430"
  GCP_REGION: "us-central1"
  DEPLOYMENT_NAME: "cognitechllc-playground-dev-project"
  GIT_DIRECTORY: "deployments/Playground/dev-project"
  WORKLOAD_IDENTITY_PROVIDER: "projects/YOUR_PROJECT_NUMBER/locations/global/workloadIdentityPools/github-pool/providers/github-provider"  # <-- UPDATE THIS
  SERVICE_ACCOUNT: "infra-manager-sa@dev-project-1430.iam.gserviceaccount.com"
```

4. Commit and push the change to GitHub

### 5. Set Up GitHub Environments

GitHub Environments provide manual approval gates for production deployments.

#### Create Production Environment (Required for Apply)

1. Go to your GitHub repository: **https://github.com/KahBrightTech/Cognitech-GCP-Network-repo**
2. Click **"Settings"** tab (top navigation)
3. In the left sidebar, click **"Environments"** (under "Code and automation")
4. Click **"New environment"** button
5. Enter environment name: **`production`** (must be exact)
6. Click **"Configure environment"**
7. Check ✅ **"Required reviewers"**
8. Add reviewers (GitHub usernames who can approve deployments)
   - Add yourself and/or team members
   - At least 1 reviewer required
9. (Optional) Set **"Wait timer"** if you want a delay before deployment
10. (Optional) Set **"Deployment branches"** to restrict to `main` branch only
11. Click **"Save protection rules"**

#### Create Production-Destroy Environment (Required for Destroy)

12. Click **"New environment"** again
13. Enter environment name: **`production-destroy`** (must be exact)
14. Click **"Configure environment"**
15. Check ✅ **"Required reviewers"**
16. Add reviewers (same as above or different - these approve deletions)
17. Click **"Save protection rules"**

**Why Two Environments?**
- `production` - Requires approval to CREATE/UPDATE infrastructure
- `production-destroy` - Requires separate approval to DELETE infrastructure (additional safety)

### 6. Verify Service Account Permissions

The service account needs specific IAM roles to deploy infrastructure.

#### Option A: Using GCP Console

1. Go to [IAM & Admin → IAM](https://console.cloud.google.com/iam-admin/iam)
2. Select project: **dev-project-1430**
3. Find **infra-manager-sa@dev-project-1430.iam.gserviceaccount.com** in the list
4. Click the pencil icon (✏️) to edit permissions
5. Verify or add these roles:
   - ✅ **Infrastructure Manager Agent** (`roles/config.agent`)
   - ✅ **IAM Security Admin** (`roles/iam.securityAdmin`)
   - ✅ **Service Account Admin** (`roles/iam.serviceAccountAdmin`)
   - ✅ **Storage Admin** (`roles/storage.admin`)
   - ✅ **Editor** (`roles/editor`) - if already exists

6. For organization-level custom roles (optional):
   - Go to [IAM & Admin → IAM](https://console.cloud.google.com/iam-admin/iam) at the **organization level**
   - Select organization: **cognitechllc.org** (ID: 43129013392)
   - Add the service account with **Organization Role Administrator** role

#### Option B: Using gcloud CLI

```bash
# Project-level roles
gcloud projects add-iam-policy-binding dev-project-1430 \
  --member="serviceAccount:infra-manager-sa@dev-project-1430.iam.gserviceaccount.com" \
  --role="roles/config.agent"

gcloud projects add-iam-policy-binding dev-project-1430 \
  --member="serviceAccount:infra-manager-sa@dev-project-1430.iam.gserviceaccount.com" \
  --role="roles/iam.securityAdmin"

gcloud projects add-iam-policy-binding dev-project-1430 \
  --member="serviceAccount:infra-manager-sa@dev-project-1430.iam.gserviceaccount.com" \
  --role="roles/iam.serviceAccountAdmin"

gcloud projects add-iam-policy-binding dev-project-1430 \
  --member="serviceAccount:infra-manager-sa@dev-project-1430.iam.gserviceaccount.com" \
  --role="roles/storage.admin"

# Organization-level role (for org custom roles)
gcloud organizations add-iam-policy-binding 43129013392 \
  --member="serviceAccount:infra-manager-sa@dev-project-1430.iam.gserviceaccount.com" \
  --role="roles/iam.organizationRoleAdmin"
```

## Workflow Usage

### Automatic Plan on Push
The workflow automatically runs a plan when you:
- Push to `main` branch
- Push to any feature branch
- Modify files in the deployment paths

### Manual Apply
1. Go to Actions tab in GitHub
2. Select "Deploy-Playground-Dev-Project" workflow
3. Click "Run workflow"
4. Select:
   - **Branch:** `main`
   - **Action:** `apply`
5. Click "Run workflow"
6. Wait for Plan job to complete
7. Approve the deployment in the Environments section
8. Apply job will execute

### Manual Destroy
1. Go to Actions tab in GitHub
2. Select "Deploy-Playground-Dev-Project" workflow
3. Click "Run workflow"
4. Select:
   - **Branch:** `main`
   - **Action:** `destroy`
5. Click "Run workflow"
6. Approve the destruction in the Environments section
7. Destroy job will execute

## Workflow Stages

### 1. Plan Stage
- Authenticates to GCP using Workload Identity
- Uploads deployment config to GCS
- Runs Infrastructure Manager preview (plan)
- Reports changes in GitHub Actions summary

### 2. Approve Stage (Manual Apply Only)
- Requires manual approval via GitHub Environments
- Only runs on `main` branch
- Prevents accidental infrastructure changes

### 3. Apply Stage (Manual Apply Only)
- Applies infrastructure changes
- Creates/updates:
  - Custom IAM roles
  - Service accounts
  - IAM bindings
- Provides detailed summary

### 4. Destroy Stage (Manual Destroy Only)
- Requires manual approval via separate environment
- Destroys all managed infrastructure
- Only runs on `main` branch

## Troubleshooting

### Common Setup Issues

#### ❌ Error: "Failed to authenticate to Google Cloud"

**Cause:** Workload Identity Federation not properly configured

**Solution - Via Console:**
1. Go to [Workload Identity Federation](https://console.cloud.google.com/iam-admin/workload-identity-pools)
2. Verify `github-pool` exists and is enabled
3. Click on `github-pool` → `github-provider`
4. Check that Issuer URL is: `https://token.actions.githubusercontent.com`
5. Verify attribute mappings are set correctly (see Step 2)
6. Go to [Service Accounts](https://console.cloud.google.com/iam-admin/serviceaccounts)
7. Click on `infra-manager-sa`
8. Check "Permissions" tab has principal with format:
   ```
   principalSet://iam.googleapis.com/projects/PROJECT_NUMBER/locations/global/workloadIdentityPools/github-pool/attribute.repository/KahBrightTech/Cognitech-GCP-Network-repo
   ```

**Solution - Via CLI:**
```bash
# Verify Workload Identity Pool
gcloud iam workload-identity-pools describe github-pool \
  --location=global \
  --project=dev-project-1430

# Verify provider
gcloud iam workload-identity-pools providers describe github-provider \
  --location=global \
  --workload-identity-pool=github-pool \
  --project=dev-project-1430

# Check service account bindings
gcloud iam service-accounts get-iam-policy \
  infra-manager-sa@dev-project-1430.iam.gserviceaccount.com \
  --project=dev-project-1430
```

#### ❌ Error: "API [config.googleapis.com] not enabled"

**Cause:** Infrastructure Manager API not enabled

**Solution - Via Console:**
1. Go to [APIs & Services → Dashboard](https://console.cloud.google.com/apis/dashboard)
2. Check if "Infrastructure Manager API" is listed
3. If not, go to [API Library](https://console.cloud.google.com/apis/library)
4. Search for "Infrastructure Manager API"
5. Click **"Enable"**

**Solution - Via CLI:**
```bash
gcloud services enable config.googleapis.com --project=dev-project-1430
```

#### ❌ Error: "Permission denied on resource project"

**Cause:** Service account missing required IAM roles

**Solution - Via Console:**
1. Go to [IAM & Admin → IAM](https://console.cloud.google.com/iam-admin/iam)
2. Find `infra-manager-sa@dev-project-1430.iam.gserviceaccount.com`
3. Click pencil icon to edit
4. Verify all required roles from Step 6 are present
5. If missing, click "Add Another Role" and add them

**Solution - Via CLI:**
```bash
# Check current roles
gcloud projects get-iam-policy dev-project-1430 \
  --flatten="bindings[].members" \
  --filter="bindings.members:serviceAccount:infra-manager-sa@dev-project-1430.iam.gserviceaccount.com"
```

#### ❌ Error: "Environment 'production' not found"

**Cause:** GitHub Environment not created or misspelled

**Solution:**
1. Go to GitHub repository **Settings** → **Environments**
2. Check if environment named exactly `production` exists (case-sensitive)
3. If not, create it following Step 5 instructions
4. Ensure environment name matches exactly what's in the workflow file

#### ❌ Error: "WORKLOAD_IDENTITY_PROVIDER not set correctly"

**Cause:** Provider path not updated in workflow file

**Solution - Via Console:**
1. Go to [Workload Identity Federation](https://console.cloud.google.com/iam-admin/workload-identity-pools)
2. Click `github-pool` → `github-provider`
3. Copy the **"Provider resource name"** at the top
4. Edit [.github/workflows/deploy-playground-dev-project.yaml](.github/workflows/deploy-playground-dev-project.yaml)
5. Replace the `WORKLOAD_IDENTITY_PROVIDER` value with the copied path
6. Commit and push the change

### Viewing Deployment Logs

#### Via GCP Console

1. Go to [Infrastructure Manager → Deployments](https://console.cloud.google.com/infrastructure-manager/deployments)
2. Select region: **us-central1**
3. Click on: **cognitechllc-playground-dev-project**
4. View:
   - **Overview** - Current state and metadata
   - **Revisions** - History of all deployments
   - **Outputs** - Terraform outputs
   - **Preview** - Pending changes (from plan)
5. For detailed logs, click on a revision and view "Logs" section

#### Via gcloud CLI

```bash
# View deployment details
gcloud infra-manager deployments describe \
  projects/dev-project-1430/locations/us-central1/deployments/cognitechllc-playground-dev-project \
  --format=yaml

# List all deployments
gcloud infra-manager deployments list \
  --location=us-central1 \
  --project=dev-project-1430
```

### Viewing Workflow Logs in GitHub

1. Go to **Actions** tab in your GitHub repository
2. Click on the workflow run you want to inspect
3. Click on individual job names to see detailed logs:
   - **plan** - See what changes will be made
   - **apply** - See deployment execution
   - **destroy** - See destruction execution
4. Download logs if needed: Click ⚙️ (gear icon) → Download log archive

## Quick Test - Verify Setup

After completing all setup steps, test the workflow to ensure everything works.

### Test 1: Automatic Plan (No Approval Required)

1. Make a small change to your deployment config:
   ```bash
   # Edit deployment-config.yaml
   # Example: Add a comment or modify a description
   ```
2. Commit and push to a feature branch:
   ```bash
   git checkout -b test-workflow
   git add .
   git commit -m "test: verify workflow setup"
   git push origin test-workflow
   ```
3. Go to GitHub **Actions** tab
4. You should see a new workflow run automatically started
5. Wait for the **plan** job to complete (should succeed)
6. Review the output - it should show "Plan completed successfully"

**Expected Result:** ✅ Plan job completes without errors

### Test 2: Manual Apply with Approval

1. Go to GitHub **Actions** tab
2. Click **"Deploy-Playground-Dev-Project"** workflow
3. Click **"Run workflow"** button
4. Select:
   - **Branch:** `main`
   - **Action:** `plan` (start with plan only)
5. Click **"Run workflow"**
6. Wait for plan to complete
7. Review the planned changes

8. Once comfortable, run again with:
   - **Branch:** `main`
   - **Action:** `apply`
9. The workflow will pause at "approve" job
10. Go to the workflow run page
11. Click **"Review deployments"** button
12. Select `production` environment
13. Click **"Approve and deploy"**
14. The **apply** job will start
15. Monitor the deployment logs

**Expected Result:** ✅ Resources created successfully in GCP

### Test 3: Verify Resources in GCP Console

After successful apply, verify resources were created:

1. **Custom Roles:**
   - Go to [IAM & Admin → Roles](https://console.cloud.google.com/iam-admin/roles)
   - Find: `appDeployer` and `networkViewer` (or your custom roles)

2. **Service Accounts:**
   - Go to [IAM & Admin → Service Accounts](https://console.cloud.google.com/iam-admin/serviceaccounts)
   - Find: `ci-cd-pipeline-sa` and `app-backend-sa` (or your service accounts)

3. **IAM Bindings:**
   - Go to [IAM & Admin → IAM](https://console.cloud.google.com/iam-admin/iam)
   - Verify users/service accounts have the roles you configured

4. **Infrastructure Manager:**
   - Go to [Infrastructure Manager → Deployments](https://console.cloud.google.com/infrastructure-manager/deployments)
   - Should show: `cognitechllc-playground-dev-project` with status "Active"

**Expected Result:** ✅ All resources visible in console

### Validation Checklist

After testing, verify:

- [ ] Plan job runs automatically on push
- [ ] Manual workflow dispatch works
- [ ] Approval gate prevents accidental deployment
- [ ] Apply job creates resources successfully
- [ ] Resources visible in GCP Console
- [ ] Service account has proper permissions
- [ ] No authentication errors in logs
- [ ] Deployment shows "APPLIED" status in Infrastructure Manager

If all checks pass, your workflow is ready for production use! 🎉

## Security Best Practices

1. **Least Privilege:** Service account has only required permissions
2. **Keyless Authentication:** No service account keys stored in GitHub
3. **Environment Protection:** Manual approval required for production changes
4. **Audit Trail:** All actions logged in GitHub Actions history
5. **Branch Protection:** Apply/Destroy only work on `main` branch

## Monitoring

Monitor deployments in GCP Console:
- Infrastructure Manager → Deployments
- View deployment history, logs, and state

Monitor GitHub Actions:
- Actions tab → Recent workflow runs
- View execution logs and summaries

## Additional Resources

- [GCP Workload Identity Federation](https://cloud.google.com/iam/docs/workload-identity-federation)
- [Infrastructure Manager Documentation](https://cloud.google.com/infrastructure-manager/docs)
- [GitHub Actions Documentation](https://docs.github.com/en/actions)
