# DNS Configuration Guide for zohaib.no

**Quick Reference for setting up DNS records to point your domain to your AWS server**

---

## Server Information

- **Domain**: zohaib.no
- **Server IP**: 18.223.101.101
- **Server Location**: AWS (Amazon Web Services)

---

## DNS Records to Add

Add these exact records in your domain registrar's DNS management panel:

### Record 1: Root Domain
| Field | Value |
|-------|-------|
| **Type** | A |
| **Name/Host** | @ (or leave blank, or "zohaib.no") |
| **Value/Points To** | 18.223.101.101 |
| **TTL** | 3600 (or 1 hour) |

**What this does**: Points zohaib.no to your server

---

### Record 2: WWW Subdomain
| Field | Value |
|-------|-------|
| **Type** | A |
| **Name/Host** | www |
| **Value/Points To** | 18.223.101.101 |
| **TTL** | 3600 (or 1 hour) |

**What this does**: Points www.zohaib.no to your server

---

## Step-by-Step Instructions

### Step 1: Log Into Your Domain Registrar

Go to the website where you registered zohaib.no.

**Common registrars**:
- **GoDaddy**: https://www.godaddy.com/ → Sign In
- **Namecheap**: https://www.namecheap.com/ → Sign In
- **Google Domains**: https://domains.google/ → Sign In
- **Cloudflare**: https://dash.cloudflare.com/ → Log In
- **AWS Route 53**: https://console.aws.amazon.com/route53/ → Sign In
- **Other**: Check your email for registration confirmation to find registrar

---

### Step 2: Find DNS Management

Look for one of these sections:
- "DNS Management"
- "DNS Settings"
- "Manage DNS"
- "DNS Records"
- "Advanced DNS"
- "Domain Settings" → "DNS"

---

### Step 3: Add First DNS Record (Root Domain)

1. Click "Add Record" or "Add New Record" or "+"
2. Fill in the fields:
   - **Type**: Select "A" from dropdown
   - **Name/Host**: Enter `@` (or leave blank, or enter "zohaib.no")
   - **Value/Points To/Address**: Enter `18.223.101.101`
   - **TTL**: Enter `3600` or select "1 hour" (or leave default)
3. Click "Save" or "Add Record"

---

### Step 4: Add Second DNS Record (WWW Subdomain)

1. Click "Add Record" again
2. Fill in the fields:
   - **Type**: Select "A" from dropdown
   - **Name/Host**: Enter `www`
   - **Value/Points To/Address**: Enter `18.223.101.101`
   - **TTL**: Enter `3600` or select "1 hour" (or leave default)
3. Click "Save" or "Add Record"

---

### Step 5: Save Changes

- Some registrars auto-save, others require clicking "Save Changes" or "Apply"
- Look for a confirmation message

---

## Registrar-Specific Instructions

### GoDaddy

1. Log in to https://account.godaddy.com/
2. Click "My Products"
3. Find "Domains" → Click "DNS" next to zohaib.no
4. Scroll to "Records" section
5. Click "Add" button
6. For root domain:
   - Type: A
   - Name: @
   - Value: 18.223.101.101
   - TTL: 1 Hour
7. Click "Save"
8. Click "Add" again for www
9. For www subdomain:
   - Type: A
   - Name: www
   - Value: 18.223.101.101
   - TTL: 1 Hour
10. Click "Save"

---

### Namecheap

1. Log in to https://www.namecheap.com/
2. Click "Domain List" in left sidebar
3. Click "Manage" next to zohaib.no
4. Click "Advanced DNS" tab
5. Under "Host Records", click "Add New Record"
6. For root domain:
   - Type: A Record
   - Host: @
   - Value: 18.223.101.101
   - TTL: Automatic
7. Click green checkmark ✓
8. Click "Add New Record" again
9. For www subdomain:
   - Type: A Record
   - Host: www
   - Value: 18.223.101.101
   - TTL: Automatic
10. Click green checkmark ✓
11. Wait 30 minutes for propagation

---

### Google Domains

1. Log in to https://domains.google.com/
2. Click on zohaib.no
3. Click "DNS" in left sidebar
4. Scroll to "Custom resource records"
5. For root domain:
   - Name: @ (or blank)
   - Type: A
   - TTL: 1H
   - Data: 18.223.101.101
6. Click "Add"
7. For www subdomain:
   - Name: www
   - Type: A
   - TTL: 1H
   - Data: 18.223.101.101
8. Click "Add"

---

### Cloudflare

1. Log in to https://dash.cloudflare.com/
2. Click on zohaib.no
3. Click "DNS" in top menu
4. Click "Add record"
5. For root domain:
   - Type: A
   - Name: @
   - IPv4 address: 18.223.101.101
   - Proxy status: DNS only (gray cloud) ← IMPORTANT
   - TTL: Auto
6. Click "Save"
7. Click "Add record" again
8. For www subdomain:
   - Type: A
   - Name: www
   - IPv4 address: 18.223.101.101
   - Proxy status: DNS only (gray cloud) ← IMPORTANT
   - TTL: Auto
9. Click "Save"

**Note**: For Cloudflare, make sure "Proxy status" is set to "DNS only" (gray cloud icon), NOT proxied (orange cloud), especially when setting up SSL for the first time.

---

### AWS Route 53

1. Log in to https://console.aws.amazon.com/route53/
2. Click "Hosted zones"
3. Click on zohaib.no
4. Click "Create record"
5. For root domain:
   - Record name: (leave blank)
   - Record type: A
   - Value: 18.223.101.101
   - TTL: 300
   - Routing policy: Simple routing
6. Click "Create records"
7. Click "Create record" again
8. For www subdomain:
   - Record name: www
   - Record type: A
   - Value: 18.223.101.101
   - TTL: 300
   - Routing policy: Simple routing
9. Click "Create records"

---

## Verification

### Wait for Propagation

DNS changes take time to propagate:
- **Minimum**: 5-15 minutes
- **Typical**: 30 minutes to 2 hours
- **Maximum**: Up to 48 hours (rare)

---

### Check DNS Propagation

#### Method 1: Using nslookup (Mac/Linux/Windows)

Open Terminal (Mac/Linux) or Command Prompt (Windows):

```bash
nslookup zohaib.no
```

**Expected output**:
```
Server:  ...
Address: ...

Non-authoritative answer:
Name:    zohaib.no
Address: 18.223.101.101
```

Also check www:
```bash
nslookup www.zohaib.no
```

**Expected output**:
```
Name:    www.zohaib.no
Address: 18.223.101.101
```

---

#### Method 2: Using dig (Mac/Linux)

```bash
dig zohaib.no +short
```

**Expected output**:
```
18.223.101.101
```

Also check www:
```bash
dig www.zohaib.no +short
```

**Expected output**:
```
18.223.101.101
```

---

#### Method 3: Using ping

```bash
ping zohaib.no
```

**Expected output**:
```
PING zohaib.no (18.223.101.101): 56 data bytes
64 bytes from 18.223.101.101: icmp_seq=0 ttl=...
...
```

Press Ctrl+C to stop.

---

#### Method 4: Online Tools

1. **DNS Checker** (checks globally):
   - Go to https://dnschecker.org/
   - Enter "zohaib.no" in the search box
   - Select "A" record type
   - Click "Search"
   - Should show 18.223.101.101 across multiple locations

2. **What's My DNS**:
   - Go to https://www.whatsmydns.net/
   - Enter "zohaib.no"
   - Should show 18.223.101.101

3. **MX Toolbox**:
   - Go to https://mxtoolbox.com/DNSLookup.aspx
   - Enter "zohaib.no"
   - Should show A record pointing to 18.223.101.101

---

## Common Issues and Solutions

### Issue 1: DNS not propagating

**Solution**:
- Wait longer (up to 24 hours)
- Try clearing your local DNS cache:
  - **Mac**: `sudo dscacheutil -flushcache; sudo killall -HUP mDNSResponder`
  - **Windows**: `ipconfig /flushdns`
  - **Linux**: `sudo systemd-resolve --flush-caches`
- Try from a different network (mobile hotspot)
- Use online tools to check if it's propagated globally

---

### Issue 2: Wrong IP address showing

**Solution**:
- Double-check you entered 18.223.101.101 correctly
- Delete old DNS records pointing to different IPs
- Make sure you saved the changes in your registrar
- Wait for TTL to expire (usually 1 hour)

---

### Issue 3: Only www works (or only root domain works)

**Solution**:
- Make sure you added BOTH records:
  - @ (or blank) for zohaib.no
  - www for www.zohaib.no
- Check both records are type "A", not CNAME
- Check both point to the same IP: 18.223.101.101

---

### Issue 4: Registrar says "Record already exists"

**Solution**:
- You may have existing DNS records
- **Option 1**: Edit the existing record to point to 18.223.101.101
- **Option 2**: Delete the old record and create a new one
- Be careful not to delete MX records (email) or other important records

---

### Issue 5: Cloudflare SSL error

**Solution**:
- If using Cloudflare, set SSL/TLS mode to "Flexible" initially
- Go to SSL/TLS → Overview → Set to "Flexible"
- After Let's Encrypt certificate is installed on your server, change to "Full (strict)"
- Make sure Proxy Status is "DNS only" (gray cloud) when setting up

---

## After DNS is Working

Once `nslookup zohaib.no` returns 18.223.101.101:

1. ✅ **Test HTTP access**:
   ```bash
   curl http://zohaib.no/api/projects/
   ```
   Or open in browser: http://zohaib.no

2. ✅ **Proceed to SSL setup** (Phase 3 of deployment)

3. ✅ **Switch to Phase 2 .env configuration** (HTTPS with security enabled)

---

## DNS Record Summary

After configuration, your DNS should look like this:

| Type | Name | Value | TTL |
|------|------|-------|-----|
| A    | @    | 18.223.101.101 | 3600 |
| A    | www  | 18.223.101.101 | 3600 |

**Optional additional records** (if needed later):
- MX records (for email)
- TXT records (for domain verification, SPF, DKIM)
- CNAME records (for subdomains like api.zohaib.no)

---

## Quick Reference Commands

```bash
# Check DNS resolution
nslookup zohaib.no
nslookup www.zohaib.no

# Check with dig (more detailed)
dig zohaib.no +short
dig www.zohaib.no +short

# Test connectivity
ping zohaib.no
ping www.zohaib.no

# Test HTTP access
curl http://zohaib.no/api/projects/
curl http://www.zohaib.no/api/projects/

# Clear local DNS cache (if needed)
# Mac:
sudo dscacheutil -flushcache; sudo killall -HUP mDNSResponder

# Windows:
ipconfig /flushdns

# Linux:
sudo systemd-resolve --flush-caches
```

---

## Need Help?

If you're stuck:

1. Check your domain registrar's help documentation
2. Contact your registrar's support
3. Use online DNS checking tools to diagnose
4. Check if your domain is locked (needs to be unlocked)
5. Verify you have permission to modify DNS records

---

**Once DNS is working, return to the main deployment instructions to continue with SSL setup!**
