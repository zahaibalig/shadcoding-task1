# CircleCI & CI/CD Complete Learning Guide

> **A comprehensive guide to understanding Continuous Integration and Continuous Deployment with CircleCI**

---

## Table of Contents
1. [What is CI/CD?](#what-is-cicd)
2. [Why Do We Need CI/CD?](#why-do-we-need-cicd)
3. [Understanding CircleCI](#understanding-circleci)
4. [Your Pipeline Architecture](#your-pipeline-architecture)
5. [CircleCI Concepts Explained](#circleci-concepts-explained)
6. [Environment Variables & Secrets](#environment-variables--secrets)
7. [SSH Deployment Setup](#ssh-deployment-setup)
8. [Monitoring Builds](#monitoring-builds)
9. [Debugging Failed Builds](#debugging-failed-builds)
10. [Best Practices](#best-practices)

---

## What is CI/CD?

### Continuous Integration (CI)
**Continuous Integration** is the practice of automatically testing your code every time you push changes to your repository.

**Before CI (Manual Testing):**
```
Developer writes code
    ↓
Developer manually runs tests on their computer
    ↓
Developer pushes code to GitHub
    ↓
❌ Other developers pull the code and it breaks because:
   - Tests weren't run properly
   - Code works on one computer but not others
   - Dependencies are different
```

**With CI (Automated Testing):**
```
Developer writes code
    ↓
Developer pushes code to GitHub
    ↓
✅ CircleCI automatically:
   - Pulls the latest code
   - Sets up a fresh environment
   - Installs all dependencies
   - Runs ALL tests
   - Reports if anything fails
    ↓
If tests pass ✅ → Code is safe to merge
If tests fail ❌ → Fix before merging
```

### Continuous Deployment (CD)
**Continuous Deployment** is the practice of automatically deploying your application when code passes all tests.

**Before CD (Manual Deployment):**
```
Tests pass locally
    ↓
Developer manually SSHs into server
    ↓
Developer manually pulls code
    ↓
Developer manually builds frontend
    ↓
Developer manually restarts services
    ↓
❌ Takes 15-20 minutes, error-prone, inconsistent
```

**With CD (Automated Deployment):**
```
Tests pass in CircleCI
    ↓
✅ CircleCI automatically:
   - SSHs into your AWS server
   - Pulls latest code
   - Builds frontend
   - Restarts services
   - Verifies deployment
    ↓
Your website is updated in 5 minutes, consistently, every time!
```

---

## Why Do We Need CI/CD?

### 1. **Catch Bugs Early**
Without CI/CD, you might not discover bugs until they're already on your production server affecting users.

**Example:**
```typescript
// You change this function:
function calculateTotal(items) {
  return items.map(i => i.price).reduce((a, b) => a + b)
}

// But you didn't test with empty arrays!
calculateTotal([]) // ❌ CRASH! reduce() needs initial value
```

With CI/CD, your automated tests would catch this **before** it reaches production.

### 2. **Consistent Deployments**
Every deployment happens the exact same way, eliminating human error.

**Manual Deployment Problems:**
- "Did I restart Gunicorn?"
- "Did I run migrations?"
- "Did I build the frontend with the right command?"

**With CI/CD:**
- ✅ Same steps every time
- ✅ No forgotten steps
- ✅ Full audit trail

### 3. **Faster Development Cycle**
Deploy multiple times per day instead of once per week.

**Before:**
```
Write feature → Wait days → Manual testing → Deploy (risky)
```

**After:**
```
Write feature → Auto test → Auto deploy → Users get feature (safe!)
```

### 4. **Team Collaboration**
Multiple developers can work on the same project without breaking each other's code.

### 5. **Confidence**
You know that if CI passes, your code is safe to deploy. No more "I hope this works!" deployments.

---

## Understanding CircleCI

### What is CircleCI?
CircleCI is a **cloud-based CI/CD platform** that runs your tests and deployments automatically when you push code to GitHub.

### How Does CircleCI Work?

```
┌─────────────────────────────────────────────────────────┐
│  1. You push code to GitHub                             │
│     git push origin main                                │
└────────────────────┬────────────────────────────────────┘
                     │
                     ▼
┌─────────────────────────────────────────────────────────┐
│  2. GitHub webhook notifies CircleCI                    │
│     "New commit detected on main branch!"               │
└────────────────────┬────────────────────────────────────┘
                     │
                     ▼
┌─────────────────────────────────────────────────────────┐
│  3. CircleCI reads .circleci/config.yml                 │
│     "What should I do with this code?"                  │
└────────────────────┬────────────────────────────────────┘
                     │
                     ▼
┌─────────────────────────────────────────────────────────┐
│  4. CircleCI spins up Docker containers                 │
│     - Python 3.11 container for backend                 │
│     - Node 20.19 container for frontend                 │
└────────────────────┬────────────────────────────────────┘
                     │
                     ▼
┌─────────────────────────────────────────────────────────┐
│  5. CircleCI runs your jobs in parallel                 │
│     ┌─────────────────┐  ┌─────────────────┐          │
│     │  test-backend   │  │  test-frontend  │          │
│     │  (17 tests)     │  │  (30 tests)     │          │
│     └─────────────────┘  └─────────────────┘          │
└────────────────────┬────────────────────────────────────┘
                     │
                     ▼
┌─────────────────────────────────────────────────────────┐
│  6. If tests pass, build frontend                       │
│     npm run build → Creates production bundle           │
└────────────────────┬────────────────────────────────────┘
                     │
                     ▼
┌─────────────────────────────────────────────────────────┐
│  7. If build succeeds, deploy to AWS                    │
│     SSH into 18.217.70.110 → Run deploy.sh             │
└────────────────────┬────────────────────────────────────┘
                     │
                     ▼
┌─────────────────────────────────────────────────────────┐
│  8. CircleCI reports success or failure                 │
│     ✅ All jobs passed! Deployment successful!          │
└─────────────────────────────────────────────────────────┘
```

---

## Your Pipeline Architecture

### File: `.circleci/config.yml`

This file defines your entire CI/CD pipeline. Let's break it down:

### 1. Executors (Docker Images)

```yaml
executors:
  python-executor:
    docker:
      - image: cimg/python:3.11

  node-executor:
    docker:
      - image: cimg/node:20.19
```

**What are executors?**
Think of executors as "virtual computers" that CircleCI creates for your jobs.

- `python-executor`: A computer with Python 3.11 installed
- `node-executor`: A computer with Node.js 20.19 installed

**Why separate executors?**
Your backend needs Python, your frontend needs Node.js. CircleCI creates the right environment for each job.

### 2. Jobs (Tasks to Execute)

#### Job 1: `test-backend`

```yaml
test-backend:
  executor: python-executor
  steps:
    - checkout                           # Get code from GitHub
    - restore_cache                      # Restore cached dependencies
    - run: pip install -r requirements.txt
    - save_cache                         # Cache dependencies for next time
    - run: python manage.py test         # Run Django tests
    - run: python manage.py makemigrations --check
```

**What happens here?**
1. CircleCI creates a Python 3.11 container
2. Clones your GitHub repository into the container
3. Checks if it already has your Python dependencies cached (faster!)
4. Installs Django, DRF, and other dependencies
5. Runs your 17 backend tests
6. Checks if you forgot to create any migrations

**Why cache dependencies?**
Installing dependencies takes time. CircleCI caches them so the second build is much faster!
- First build: 2 minutes to install dependencies
- Subsequent builds: 10 seconds (cached!)

#### Job 2: `test-frontend`

```yaml
test-frontend:
  executor: node-executor
  steps:
    - checkout
    - restore_cache
    - run: npm ci                        # Clean install (like npm install)
    - save_cache
    - run: npm run type-check           # TypeScript type checking
    - run: npm test -- --run            # Run Vitest tests
```

**What happens here?**
1. CircleCI creates a Node.js 20.19 container
2. Clones your repository
3. Installs npm dependencies (Vue, Vite, Vitest, etc.)
4. Runs TypeScript compiler to check for type errors
5. Runs your 30 frontend tests

**Why `npm ci` instead of `npm install`?**
`npm ci` (clean install) is faster and more reliable in CI environments. It installs exactly what's in `package-lock.json`.

#### Job 3: `build-frontend`

```yaml
build-frontend:
  executor: node-executor
  steps:
    - checkout
    - restore_cache
    - run: npm ci
    - run: npm run build                 # Vite builds production bundle
    - persist_to_workspace:              # Save build for deployment
        paths:
          - frontend/dist
```

**What happens here?**
1. Builds your Vue.js app for production
2. Saves the `frontend/dist` folder to a "workspace"
3. The deploy job can access this build later

**What's in frontend/dist?**
```
frontend/dist/
├── index.html              # Main HTML file
├── assets/
│   ├── index-a1b2c3.js    # Minified JavaScript
│   ├── index-d4e5f6.css   # Minified CSS
│   └── logo-g7h8i9.png    # Optimized images
```

Vite creates optimized, minified files ready for production!

#### Job 4: `deploy`

```yaml
deploy:
  executor: python-executor
  steps:
    - checkout
    - attach_workspace                   # Get frontend build from previous job
    - add_ssh_keys:                      # Load SSH key to access AWS server
        fingerprints:
          - "${SSH_KEY_FINGERPRINT}"
    - run: ssh-keyscan -H ${SERVER_IP} >> ~/.ssh/known_hosts
    - run: |
        scp deployment/deploy.sh ${DEPLOY_USER}@${SERVER_IP}:/tmp/
        scp -r frontend/dist ${DEPLOY_USER}@${SERVER_IP}:/tmp/
        ssh ${DEPLOY_USER}@${SERVER_IP} 'bash /tmp/deploy.sh'
```

**What happens here?**
1. Loads the frontend build from the previous job
2. Adds your SSH private key (stored securely in CircleCI)
3. Adds your server to known_hosts (prevents SSH prompt)
4. Copies `deploy.sh` script to your AWS server
5. Copies the frontend build to your server
6. SSHs into your server and runs the deployment script
7. Your `deploy.sh` script then:
   - Pulls latest backend code
   - Installs Python dependencies
   - Runs migrations
   - Copies frontend build to Nginx directory
   - Restarts Gunicorn and Nginx

### 3. Workflows (Orchestration)

```yaml
workflows:
  test-and-deploy:
    jobs:
      - test-backend
      - test-frontend
      - build-frontend:
          requires:
            - test-frontend           # Wait for frontend tests to pass
      - deploy:
          requires:
            - test-backend            # Wait for backend tests to pass
            - build-frontend          # Wait for frontend build to complete
          filters:
            branches:
              only:
                - main                 # Only deploy from main branch
                - master
```

**Workflow Visualization:**

```
Git push to main
       │
       ├────────────────────┐
       ▼                    ▼
  test-backend        test-frontend
   (parallel)           (parallel)
       │                    │
       │                    ▼
       │              build-frontend
       │                    │
       └────────┬───────────┘
                ▼
              deploy
         (only if all pass)
```

**Key Points:**
- `test-backend` and `test-frontend` run **in parallel** (faster!)
- `build-frontend` waits for `test-frontend` to pass
- `deploy` waits for **both** test jobs and build to pass
- Deployment only happens on `main` or `master` branch
- If ANY job fails, deployment doesn't happen ✅ Safety!

---

## CircleCI Concepts Explained

### 1. Checksum Caching

```yaml
- restore_cache:
    keys:
      - backend-deps-{{ checksum "requirements.txt" }}
      - backend-deps-
```

**What is `{{ checksum "requirements.txt" }}`?**

It's a unique fingerprint of your `requirements.txt` file. Example:
```
requirements.txt unchanged → checksum: a7f3b9c2
requirements.txt changed   → checksum: e4d8k1m6
```

CircleCI looks for a cache with this exact checksum. If found, it restores dependencies instantly!

**Cache Keys Explained:**
1. `backend-deps-a7f3b9c2` ← Exact match (fastest!)
2. `backend-deps-` ← Partial match fallback

### 2. Workspace vs Cache

**Cache (restore_cache / save_cache):**
- Stores `node_modules` and `pip` packages
- Persists across different pipeline runs
- Purpose: Speed up dependency installation

**Workspace (persist_to_workspace / attach_workspace):**
- Shares files between jobs in the SAME pipeline run
- Purpose: Pass build artifacts between jobs
- Example: `build-frontend` creates `dist/`, `deploy` uses it

### 3. Docker Images

```yaml
- image: cimg/python:3.11
```

**What is `cimg/python:3.11`?**
CircleCI's official Docker image with:
- Python 3.11 installed
- pip, virtualenv
- Common build tools (gcc, make, etc.)
- Git

**Why Docker?**
- Clean environment every time (no leftover files from previous builds)
- Consistent across all builds
- Isolated from other projects

### 4. Steps Execution Order

Steps run **sequentially** (one after another):
```yaml
steps:
  - checkout           # Step 1
  - restore_cache      # Step 2 (waits for Step 1)
  - run: npm install   # Step 3 (waits for Step 2)
```

But **jobs** can run in parallel:
```yaml
jobs:
  - test-backend    # Runs at same time as test-frontend
  - test-frontend   # Runs at same time as test-backend
```

---

## Environment Variables & Secrets

### What Are Environment Variables?

Environment variables store configuration values and secrets that your pipeline needs.

### Types of Secrets in Your Project

#### 1. **SSH Private Key**
Allows CircleCI to SSH into your AWS server.

```yaml
- add_ssh_keys:
    fingerprints:
      - "${SSH_KEY_FINGERPRINT}"
```

**How it works:**
1. You generate an SSH key pair on your computer:
   ```bash
   ssh-keygen -t ed25519 -C "circleci-deploy"
   # Creates: id_ed25519 (private) and id_ed25519.pub (public)
   ```
2. You add the **public key** to your AWS server (`~/.ssh/authorized_keys`)
3. You add the **private key** to CircleCI (Project Settings → SSH Keys)
4. CircleCI gets a "fingerprint" for that key (e.g., `a7:3b:9c:2e:...`)
5. In config.yml, you reference this fingerprint

#### 2. **Server Connection Variables**

```bash
SERVER_IP=18.217.70.110
DEPLOY_USER=deploy
```

**Where to add these:**
CircleCI Project Settings → Environment Variables

**How they're used:**
```bash
ssh ${DEPLOY_USER}@${SERVER_IP}
# Becomes: ssh deploy@18.217.70.110
```

#### 3. **Application Secrets** (Backend)

If your backend needs secrets (like `SECRET_KEY`, `STATENS_VEGVESEN_API_KEY`), you have two options:

**Option 1: Already on server (Recommended)**
Your `.env` file on the AWS server already has these secrets. The deploy script just restarts the services, so they're loaded from the existing `.env`.

**Option 2: Pass from CircleCI**
If you need to update secrets during deployment:
```yaml
- run:
    command: |
      ssh ${DEPLOY_USER}@${SERVER_IP} "echo 'SECRET_KEY=${DJANGO_SECRET_KEY}' >> /path/to/.env"
```

### Security Best Practices

✅ **DO:**
- Store secrets in CircleCI Environment Variables (encrypted)
- Use SSH keys instead of passwords
- Restrict SSH keys to specific commands if possible
- Use different SSH keys for different services

❌ **DON'T:**
- Hardcode secrets in `.circleci/config.yml`
- Commit secrets to Git
- Use the same password everywhere
- Share SSH keys between team members

---

## SSH Deployment Setup

### Step-by-Step SSH Configuration

#### Step 1: Generate SSH Key Pair

On your local computer:
```bash
ssh-keygen -t ed25519 -C "circleci-deploy-shadcoding" -f ~/.ssh/circleci_deploy
```

You'll get two files:
- `circleci_deploy` (private key) - Give to CircleCI
- `circleci_deploy.pub` (public key) - Put on AWS server

#### Step 2: Add Public Key to AWS Server

```bash
# Copy public key content
cat ~/.ssh/circleci_deploy.pub

# SSH into your AWS server
ssh ubuntu@18.217.70.110

# Switch to deploy user
sudo su - deploy

# Add public key to authorized_keys
echo "YOUR_PUBLIC_KEY_HERE" >> ~/.ssh/authorized_keys

# Set correct permissions (important!)
chmod 600 ~/.ssh/authorized_keys
chmod 700 ~/.ssh
```

#### Step 3: Test SSH Connection

On your local computer:
```bash
ssh -i ~/.ssh/circleci_deploy deploy@18.217.70.110

# If this works, CircleCI will work too!
```

#### Step 4: Add Private Key to CircleCI

1. Go to CircleCI → Your Project → Project Settings
2. Click **SSH Keys** in left sidebar
3. Click **Add SSH Key**
4. Hostname: `18.217.70.110`
5. Private Key: Paste contents of `circleci_deploy` file
   ```bash
   cat ~/.ssh/circleci_deploy | pbcopy  # Copies to clipboard on Mac
   ```
6. Click **Add SSH Key**
7. Copy the **Fingerprint** (looks like: `a7:3b:9c:2e:4d:...`)

#### Step 5: Add Fingerprint to config.yml

```yaml
- add_ssh_keys:
    fingerprints:
      - "a7:3b:9c:2e:4d:..."  # Replace with your actual fingerprint
```

#### Step 6: Add Environment Variables

In CircleCI Project Settings → Environment Variables:
```
Name: SERVER_IP
Value: 18.217.70.110

Name: DEPLOY_USER
Value: deploy
```

### Troubleshooting SSH Issues

#### Problem: "Permission denied (publickey)"

**Solution:**
```bash
# Check authorized_keys permissions on server
ls -la ~/.ssh/authorized_keys
# Should be: -rw------- (600)

# Fix if needed:
chmod 600 ~/.ssh/authorized_keys
chmod 700 ~/.ssh
```

#### Problem: "Host key verification failed"

**Solution:**
Add this step before SSH commands:
```yaml
- run:
    name: Add server to known hosts
    command: |
      mkdir -p ~/.ssh
      ssh-keyscan -H ${SERVER_IP} >> ~/.ssh/known_hosts
```

---

## Monitoring Builds

### CircleCI Dashboard

Access: `https://app.circleci.com/`

**Dashboard Overview:**
```
┌─────────────────────────────────────────────────────────┐
│  Pipelines                                              │
│  ┌───────────────────────────────────────────────────┐ │
│  │ main branch - #47                                 │ │
│  │ ✅ Success - 4 minutes ago                        │ │
│  │ Commit: "Add vehicle lookup feature"              │ │
│  │                                                    │ │
│  │ ✅ test-backend    (17 tests passed)              │ │
│  │ ✅ test-frontend   (30 tests passed)              │ │
│  │ ✅ build-frontend  (Build successful)             │ │
│  │ ✅ deploy          (Deployment successful)        │ │
│  └───────────────────────────────────────────────────┘ │
└─────────────────────────────────────────────────────────┘
```

### Build Statuses

| Status | Icon | Meaning |
|--------|------|---------|
| Success | ✅ | All jobs passed |
| Failed | ❌ | At least one job failed |
| Running | 🔄 | Currently executing |
| Canceled | ⛔ | Manually canceled |
| On Hold | ⏸️ | Waiting for approval |

### Email Notifications

By default, CircleCI sends emails when:
- ❌ Build fails on your branch
- ✅ Build passes after previous failure
- 📧 Someone mentions you in a commit

**Configure in:** CircleCI User Settings → Notifications

---

## Debugging Failed Builds

### Common Failure Scenarios

#### Scenario 1: Test Failure

```
❌ test-backend failed

Output:
FAILED vehicles/tests.py::TestVehicleLookup::test_valid_lookup
AssertionError: Expected 200, got 404
```

**What happened:**
One of your backend tests failed. The code has a bug.

**How to debug:**
1. Click on the failed job in CircleCI
2. Read the test output
3. Fix the bug locally
4. Run tests locally: `cd backend && python manage.py test`
5. Push fix to GitHub
6. CircleCI will automatically retry

#### Scenario 2: Dependency Installation Failed

```
❌ test-frontend failed

Output:
npm ERR! code ERESOLVE
npm ERR! ERESOLVE unable to resolve dependency tree
```

**What happened:**
There's a conflict in your `package.json` dependencies.

**How to debug:**
1. Check `package.json` for version conflicts
2. Try `npm install` locally
3. Update `package-lock.json`
4. Commit and push

#### Scenario 3: SSH Connection Failed

```
❌ deploy failed

Output:
Permission denied (publickey)
```

**What happened:**
CircleCI can't SSH into your AWS server.

**How to debug:**
1. Verify SSH key is added to CircleCI (Project Settings → SSH Keys)
2. Verify fingerprint is correct in config.yml
3. Verify public key is on AWS server:
   ```bash
   ssh ubuntu@18.217.70.110
   sudo su - deploy
   cat ~/.ssh/authorized_keys
   ```
4. Check permissions:
   ```bash
   ls -la ~/.ssh/authorized_keys  # Should be -rw-------
   ```

#### Scenario 4: Deployment Script Failed

```
❌ deploy failed

Output:
bash: /tmp/deploy.sh: No such file or directory
```

**What happened:**
The `deploy.sh` script failed to copy to the server, or the script has errors.

**How to debug:**
1. Check if `deployment/deploy.sh` exists in your repository
2. Verify the script has correct syntax:
   ```bash
   bash -n deployment/deploy.sh  # Check for syntax errors
   ```
3. Check CircleCI logs for the actual error

### Using CircleCI SSH Debug

CircleCI allows you to SSH into the build environment!

**How to enable:**
1. Go to failed build
2. Click "Rerun job with SSH"
3. CircleCI gives you an SSH command:
   ```bash
   ssh -p 64537 18.207.254.65
   ```
4. SSH into the build environment and debug interactively

---

## Best Practices

### 1. Test Locally Before Pushing

Always run tests locally before pushing to GitHub:

```bash
# Backend tests
cd backend
python manage.py test

# Frontend tests
cd frontend
npm test
npm run type-check

# Frontend build
npm run build
```

This saves you from wasting CI minutes on trivial errors.

### 2. Write Good Commit Messages

CircleCI shows commit messages in the dashboard:

❌ Bad:
```
git commit -m "fix"
git commit -m "update"
git commit -m "changes"
```

✅ Good:
```
git commit -m "fix: Handle empty array in calculateTotal function"
git commit -m "feat: Add vehicle lookup API integration"
git commit -m "test: Add unit tests for project CRUD operations"
```

### 3. Use Feature Branches

Don't push directly to `main`. Use feature branches:

```bash
git checkout -b feature/vehicle-lookup
# Make changes
git add .
git commit -m "feat: Add vehicle lookup feature"
git push origin feature/vehicle-lookup
# Open Pull Request on GitHub
```

CircleCI will test your feature branch, but won't deploy (deployment only happens on `main`).

### 4. Monitor Your CI Minutes

CircleCI gives you **free minutes per month**:
- Free plan: 2,500 minutes/month

**Tips to save minutes:**
- Use caching effectively (already configured!)
- Don't run CI on every branch (configure in CircleCI settings)
- Cancel running builds if you pushed a fix immediately after

### 5. Keep Secrets Secret

Never log secrets in your scripts:

❌ Bad:
```bash
echo "SECRET_KEY=${SECRET_KEY}"  # Visible in logs!
```

✅ Good:
```bash
echo "Configuring environment variables..."  # Don't print values
```

### 6. Pin Dependency Versions

Use exact versions in `requirements.txt` and `package.json`:

❌ Risky:
```
Django>=5.0  # Could install 5.3, 5.4, etc. (breaking changes!)
```

✅ Safe:
```
Django==5.2.7  # Exact version, predictable builds
```

### 7. Rollback Plan

If deployment fails or introduces bugs:

```bash
# SSH into server
ssh ubuntu@18.217.70.110
sudo su - deploy
cd ~/shadcoding-task1

# Rollback to previous commit
git log --oneline  # Find previous commit hash
git checkout abc123  # Previous working commit

# Redeploy
bash deployment/deploy.sh
```

---

## Next Steps

Now that you understand CI/CD and CircleCI concepts, follow the setup guide:

👉 **Read Next:** `CIRCLECI_SETUP.md`

This guide will walk you through:
1. Creating a CircleCI account
2. Connecting your GitHub repository
3. Configuring environment variables
4. Setting up SSH keys
5. Running your first build
6. Verifying deployment

---

## Additional Resources

- **CircleCI Documentation:** https://circleci.com/docs/
- **CircleCI Config Reference:** https://circleci.com/docs/configuration-reference/
- **Your Config File:** `.circleci/config.yml`
- **Your Deployment Script:** `deployment/deploy.sh`

---

**Happy Building! 🚀**
