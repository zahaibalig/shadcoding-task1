# CircleCI Setup Guide - Step by Step

> **Complete walkthrough to set up CircleCI for your ShadCoding Task1 project**

---

## Prerequisites

Before starting, make sure you have:
- ✅ GitHub account with your repository
- ✅ AWS server running and accessible (18.217.70.110)
- ✅ SSH access to your AWS server
- ✅ Project pushed to GitHub on `main` branch

---

## Table of Contents

1. [Create CircleCI Account & Connect GitHub](#step-1-create-circleci-account--connect-github)
2. [Set Up Project in CircleCI](#step-2-set-up-project-in-circleci)
3. [Generate SSH Keys for Deployment](#step-3-generate-ssh-keys-for-deployment)
4. [Add SSH Key to AWS Server](#step-4-add-ssh-key-to-aws-server)
5. [Add SSH Key to CircleCI](#step-5-add-ssh-key-to-circleci)
6. [Configure Environment Variables](#step-6-configure-environment-variables)
7. [Update CircleCI Config with SSH Fingerprint](#step-7-update-circleci-config-with-ssh-fingerprint)
8. [Trigger Your First Build](#step-8-trigger-your-first-build)
9. [Monitor and Verify](#step-9-monitor-and-verify)
10. [Troubleshooting](#troubleshooting)

---

## Step 1: Create CircleCI Account & Connect GitHub

### 1.1 Sign Up for CircleCI

1. Go to https://circleci.com/
2. Click **"Sign Up"**
3. Click **"Sign Up with GitHub"**
4. Authorize CircleCI to access your GitHub account

**Note:** You already have a CircleCI account, so you may skip the sign-up step.

### 1.2 Connect Your GitHub Repository

CircleCI will show your GitHub organizations and repositories.

---

## Step 2: Set Up Project in CircleCI

### 2.1 Navigate to Projects

1. In CircleCI dashboard, click **"Projects"** in the left sidebar
2. Find your repository: **"shadcoding-task1"**

### 2.2 Set Up Project

1. Click **"Set Up Project"** button next to your repository
2. CircleCI will detect that you already have a `.circleci/config.yml` file
3. Click **"Use Existing Config"** (don't select the starter template)
4. CircleCI will prompt you to trigger the first pipeline
5. **WAIT!** Don't trigger yet - we need to set up SSH keys and environment variables first
6. Click **"Start Building"** or close the dialog

---

## Step 3: Generate SSH Keys for Deployment

We need to create an SSH key pair that CircleCI will use to deploy to your AWS server.

### 3.1 Generate Key Pair on Your Local Computer

Open your terminal and run:

```bash
ssh-keygen -t ed25519 -C "circleci-deploy-shadcoding" -f ~/.ssh/circleci_deploy
```

**Explanation:**
- `-t ed25519`: Use modern, secure ED25519 algorithm
- `-C "circleci-deploy-shadcoding"`: Comment to identify this key
- `-f ~/.ssh/circleci_deploy`: Save to this file

**Prompts:**
```
Enter passphrase (empty for no passphrase):
```
**Press Enter** (leave empty - CircleCI can't use password-protected keys)

```
Enter same passphrase again:
```
**Press Enter again**

**Output:**
```
Your identification has been saved in /Users/yourusername/.ssh/circleci_deploy
Your public key has been saved in /Users/yourusername/.ssh/circleci_deploy.pub
```

You now have two files:
- `~/.ssh/circleci_deploy` - **Private key** (keep secret, give to CircleCI)
- `~/.ssh/circleci_deploy.pub` - **Public key** (put on AWS server)

### 3.2 View Your Keys

```bash
# View public key (this goes on server)
cat ~/.ssh/circleci_deploy.pub

# View private key (this goes to CircleCI)
cat ~/.ssh/circleci_deploy
```

---

## Step 4: Add SSH Key to AWS Server

The public key needs to be added to your AWS server's `authorized_keys` file.

### 4.1 Copy Public Key

```bash
# Copy public key to clipboard (Mac)
cat ~/.ssh/circleci_deploy.pub | pbcopy

# Copy public key to clipboard (Linux)
cat ~/.ssh/circleci_deploy.pub | xclip -selection clipboard

# Or just display it and copy manually
cat ~/.ssh/circleci_deploy.pub
```

The output looks like:
```
ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIGq7... circleci-deploy-shadcoding
```

### 4.2 SSH into Your AWS Server

```bash
ssh ubuntu@18.217.70.110
```

### 4.3 Switch to Deploy User

```bash
sudo su - deploy
```

### 4.4 Add Public Key to authorized_keys

```bash
# Create .ssh directory if it doesn't exist
mkdir -p ~/.ssh

# Open authorized_keys in editor
nano ~/.ssh/authorized_keys
```

**Paste your public key** at the end of the file (it should be one long line).

Save and exit:
- Press `Ctrl + O` (save)
- Press `Enter` (confirm)
- Press `Ctrl + X` (exit)

### 4.5 Set Correct Permissions

**IMPORTANT:** SSH is very strict about permissions!

```bash
# Set correct permissions
chmod 700 ~/.ssh
chmod 600 ~/.ssh/authorized_keys

# Verify permissions
ls -la ~/.ssh/
```

Expected output:
```
drwx------  (700)  .ssh/
-rw-------  (600)  authorized_keys
```

### 4.6 Test SSH Connection

From your local computer (open a new terminal, don't exit your SSH session yet):

```bash
ssh -i ~/.ssh/circleci_deploy deploy@18.217.70.110
```

If this works, you'll be logged into your server as the `deploy` user. **Success!** ✅

If it doesn't work, see [Troubleshooting SSH Issues](#troubleshooting-ssh-issues).

Exit the test SSH session:
```bash
exit
```

---

## Step 5: Add SSH Key to CircleCI

Now we'll give CircleCI the **private key** so it can SSH into your server.

### 5.1 Navigate to Project Settings

1. Go to CircleCI dashboard: https://app.circleci.com/
2. Click **"Projects"** in left sidebar
3. Find your **shadcoding-task1** project
4. Click the **⚙️ gear icon** (Project Settings)

### 5.2 Add SSH Key

1. In left sidebar, scroll down to **"SSH Keys"**
2. Click **"SSH Keys"**
3. Scroll down to **"Additional SSH Keys"** section
4. Click **"Add SSH Key"** button

**Form fields:**

**Hostname:**
```
18.217.70.110
```

**Private Key:**

Copy your private key:
```bash
# Mac
cat ~/.ssh/circleci_deploy | pbcopy

# Linux
cat ~/.ssh/circleci_deploy | xclip -selection clipboard

# Or display and copy manually
cat ~/.ssh/circleci_deploy
```

Paste the entire key including:
```
-----BEGIN OPENSSH PRIVATE KEY-----
...key content...
-----END OPENSSH PRIVATE KEY-----
```

5. Click **"Add SSH Key"**

### 5.3 Copy the Fingerprint

After adding the key, CircleCI will show a **Fingerprint**.

It looks like:
```
a7:3b:9c:2e:4d:8f:1a:6b:...
```

or (newer format):
```
SHA256:gH7k8L2mP4qR9sT1uV3wX5yZ...
```

**Copy this fingerprint!** You'll need it in the next step.

---

## Step 6: Configure Environment Variables

CircleCI needs to know your server IP and deployment username.

### 6.1 Navigate to Environment Variables

1. Still in **Project Settings** (⚙️ icon)
2. In left sidebar, click **"Environment Variables"**
3. Click **"Add Environment Variable"** button

### 6.2 Add SERVER_IP Variable

**Name:**
```
SERVER_IP
```

**Value:**
```
18.217.70.110
```

Click **"Add Environment Variable"**

### 6.3 Add DEPLOY_USER Variable

Click **"Add Environment Variable"** again

**Name:**
```
DEPLOY_USER
```

**Value:**
```
deploy
```

Click **"Add Environment Variable"**

### 6.4 Verify Variables

You should now see:
```
✅ SERVER_IP         (hidden value)
✅ DEPLOY_USER       (hidden value)
```

**Note:** CircleCI hides values for security. This is normal.

---

## Step 7: Update CircleCI Config with SSH Fingerprint

Now we need to add the SSH fingerprint to your `.circleci/config.yml` file.

### 7.1 Open Your Project in Your Code Editor

```bash
cd /path/to/shadcoding-task1
code .circleci/config.yml  # VS Code
# or use your preferred editor
```

### 7.2 Find the SSH Fingerprint Line

Find this section (around line 121-123):

```yaml
- add_ssh_keys:
    fingerprints:
      - "${SSH_KEY_FINGERPRINT}"
```

### 7.3 Replace with Your Actual Fingerprint

**Option 1: Use the fingerprint directly (Recommended)**

Replace the entire section with:
```yaml
- add_ssh_keys:
    fingerprints:
      - "a7:3b:9c:2e:4d:8f:1a:6b:..."  # Your actual fingerprint from Step 5.3
```

**Option 2: Use environment variable**

1. Add SSH_KEY_FINGERPRINT to CircleCI Environment Variables (like Step 6)
2. Keep the config as: `- "${SSH_KEY_FINGERPRINT}"`

**Recommendation:** Use Option 1 (direct fingerprint) - it's simpler and fingerprints aren't sensitive secrets.

### 7.4 Commit and Push Changes

```bash
git add .circleci/config.yml
git commit -m "chore: Add SSH fingerprint to CircleCI config"
git push origin main
```

**This push will trigger your first CircleCI build!** 🎉

---

## Step 8: Trigger Your First Build

### 8.1 Automatic Trigger

If you pushed changes in Step 7, CircleCI automatically started a build.

### 8.2 Manual Trigger (if needed)

If no build started:

1. Go to CircleCI dashboard
2. Click **"Projects"**
3. Find **shadcoding-task1**
4. Click **"Trigger Pipeline"** button
5. Select branch: **main**
6. Click **"Trigger Pipeline"**

---

## Step 9: Monitor and Verify

### 9.1 Watch the Build

1. Go to CircleCI dashboard: https://app.circleci.com/
2. Click **"Pipelines"** in left sidebar
3. You should see your build running

**Pipeline View:**
```
┌─────────────────────────────────────────────────────────┐
│  #1 main branch                                         │
│  🔄 Running                                             │
│  Commit: "chore: Add SSH fingerprint to CircleCI..."   │
│                                                         │
│  🔄 test-backend    (running...)                        │
│  🔄 test-frontend   (running...)                        │
│  ⏳ build-frontend  (waiting...)                        │
│  ⏳ deploy          (waiting...)                        │
└─────────────────────────────────────────────────────────┘
```

### 9.2 Check Each Job

Click on each job to see detailed logs:

**test-backend:**
```
✅ Checkout code
✅ Restore cache
✅ Install Python dependencies
✅ Run tests (17 passed)
✅ Check migrations
```

**test-frontend:**
```
✅ Checkout code
✅ Restore cache
✅ Install npm dependencies
✅ TypeScript type check
✅ Run tests (30 passed)
```

**build-frontend:**
```
✅ Build Vite production bundle
✅ Persist to workspace
```

**deploy:**
```
✅ Add SSH keys
✅ Copy deploy.sh to server
✅ Copy frontend build to server
✅ Execute deployment script
✅ Restart Gunicorn
✅ Reload Nginx
```

### 9.3 Success! 🎉

If all jobs show ✅, your CI/CD pipeline is working!

**What just happened:**
1. CircleCI detected your push to `main`
2. Ran all your tests automatically
3. Built your frontend
4. Deployed to your AWS server
5. Your website is now updated!

### 9.4 Verify Deployment on Your Server

SSH into your server and check:

```bash
ssh ubuntu@18.217.70.110

# Check Gunicorn status
sudo systemctl status gunicorn

# Check recent logs
sudo journalctl -u gunicorn -n 50

# Check Nginx status
sudo systemctl status nginx

# Verify latest code was pulled
cd /home/deploy/shadcoding-task1
git log -1
```

### 9.5 Visit Your Website

Open your browser and visit:
```
https://zohaib.no
```

or

```
http://18.217.70.110
```

Your latest code should be live! ✅

---

## Troubleshooting

### Problem: "Permission denied (publickey)" in Deploy Job

**Cause:** SSH key not configured correctly.

**Solution:**

1. **Verify public key is on server:**
   ```bash
   ssh ubuntu@18.217.70.110
   sudo su - deploy
   cat ~/.ssh/authorized_keys
   ```
   Make sure your CircleCI public key is there.

2. **Verify permissions:**
   ```bash
   ls -la ~/.ssh/
   # Should show:
   # drwx------ .ssh/
   # -rw------- authorized_keys
   ```

3. **Fix permissions if needed:**
   ```bash
   chmod 700 ~/.ssh
   chmod 600 ~/.ssh/authorized_keys
   ```

4. **Verify fingerprint in config.yml:**
   - Go to CircleCI → Project Settings → SSH Keys
   - Copy the exact fingerprint
   - Update `.circleci/config.yml` with correct fingerprint
   - Commit and push

### Problem: Tests Failing

**Cause:** Your code has bugs or dependencies changed.

**Solution:**

1. **Run tests locally:**
   ```bash
   # Backend
   cd backend
   python manage.py test

   # Frontend
   cd frontend
   npm test
   ```

2. **Fix any failures locally first**
3. **Push fix to GitHub**

### Problem: "Host key verification failed"

**Cause:** Server not in known_hosts.

**Solution:**

Your `.circleci/config.yml` should have this step (it's already there):
```yaml
- run:
    name: Add server to known hosts
    command: |
      mkdir -p ~/.ssh
      ssh-keyscan -H ${SERVER_IP} >> ~/.ssh/known_hosts
```

If it's missing, add it before SSH commands.

### Problem: Environment Variables Not Working

**Cause:** Variables not set in CircleCI.

**Solution:**

1. Go to CircleCI → Project Settings → Environment Variables
2. Verify you have:
   - `SERVER_IP`
   - `DEPLOY_USER`
3. Re-run the build

### Problem: Deployment Script Fails

**Cause:** Script has errors or missing permissions.

**Solution:**

1. **SSH into your server manually:**
   ```bash
   ssh deploy@18.217.70.110
   cd ~/shadcoding-task1
   ```

2. **Run deployment script manually:**
   ```bash
   bash deployment/deploy.sh
   ```

3. **Fix any errors** you see
4. **Update the script** and commit/push

### Problem: Build Takes Too Long

**Cause:** Dependencies not cached.

**Solution:**

Cache is already configured in your `.circleci/config.yml`. After the first build, subsequent builds will be much faster:
- First build: ~5-7 minutes
- Cached builds: ~2-3 minutes

### Problem: CircleCI Says "No Config Found"

**Cause:** `.circleci/config.yml` not in your repository.

**Solution:**

```bash
# Verify file exists
ls -la .circleci/config.yml

# If missing, make sure it's not in .gitignore
cat .gitignore | grep circleci

# Add and commit
git add .circleci/config.yml
git commit -m "chore: Add CircleCI config"
git push origin main
```

---

## Testing Your CI/CD Pipeline

### Make a Test Change

Let's test the full pipeline:

```bash
# Create a test branch
git checkout -b test-cicd

# Make a small change (e.g., update README)
echo "\nCI/CD is now configured!" >> README.md

# Commit and push
git add README.md
git commit -m "test: Verify CI/CD pipeline works"
git push origin test-cicd
```

### Watch CircleCI

1. Go to CircleCI dashboard
2. You should see a new build for `test-cicd` branch
3. Tests will run, but **deployment will NOT happen** (deploy only runs on `main` branch)

### Merge to Main

If tests pass:

```bash
git checkout main
git merge test-cicd
git push origin main
```

Now deployment will happen! ✅

---

## Next Steps

Now that CircleCI is set up, your workflow is:

```
1. Create feature branch
   git checkout -b feature/new-feature

2. Make changes and commit
   git add .
   git commit -m "feat: Add new feature"

3. Push to GitHub
   git push origin feature/new-feature

4. CircleCI runs tests automatically ✅

5. If tests pass, merge to main
   git checkout main
   git merge feature/new-feature
   git push origin main

6. CircleCI deploys automatically! 🚀

7. Your website is updated!
```

---

## CI/CD Workflow Diagram

```
Developer              GitHub              CircleCI           AWS Server
    │                     │                     │                 │
    ├─ git push ────────> │                     │                 │
    │                     │                     │                 │
    │                     ├─ webhook ─────────> │                 │
    │                     │                     │                 │
    │                     │                     ├─ Run tests      │
    │                     │                     │  (17 backend)   │
    │                     │                     │  (30 frontend)  │
    │                     │                     │                 │
    │                     │                     ├─ Build frontend │
    │                     │                     │  (Vite)         │
    │                     │                     │                 │
    │                     │                     ├─ SSH deploy ──> │
    │                     │                     │                 │
    │                     │                     │                 ├─ Pull code
    │                     │                     │                 ├─ Install deps
    │                     │                     │                 ├─ Restart services
    │                     │                     │                 │
    │                     │                     ├─ Success! ✅    │
    │                     │                     │                 │
    │ <───────── Email notification ───────────┤                 │
    │                     │                     │                 │
    └─ Visit website ────────────────────────────────────────────> │
                          │                     │                 │
                          │                     │                 │ (Updated!)
```

---

## Additional Resources

- **CircleCI Documentation:** https://circleci.com/docs/
- **Your CircleCI Dashboard:** https://app.circleci.com/
- **Learning Guide:** See `CIRCLECI_GUIDE.md` for CI/CD concepts
- **Environment Variables Template:** See `.circleci-env-template`

---

## Congratulations! 🎉

You've successfully set up CI/CD for your project!

Every time you push to `main`, your code will be:
✅ Tested automatically
✅ Built automatically
✅ Deployed automatically
✅ Live on your server in minutes

**Happy Deploying! 🚀**
