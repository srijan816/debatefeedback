# DNS and Backend Issues - Action Required

## Current Status: BACKEND ISSUE DETECTED

---

## Problem Summary

The iOS app is trying to communicate with the backend, but there are TWO issues:

### Issue 1: DNS Misconfiguration
- **Domain**: `api.genalphai.com`
- **Problem**: DNS points to Vercel, NOT your VPS
- **Expected IP**: 144.217.164.110
- **Actual Target**: Vercel servers

### Issue 2: Backend Debate Creation Failing
- **Endpoint**: `POST /api/debates/create`
- **Status**: Returns 500 Internal Server Error
- **Login**: Works correctly ✅
- **Health Check**: Works correctly ✅
- **Debate Creation**: FAILS ❌

---

## Test Results

### ✅ Working Endpoints

**Health Check:**
```bash
curl http://144.217.164.110:12000/api/health
```
Response: `{"status":"ok","timestamp":"...","uptime":680.026}`

**Login:**
```bash
curl -X POST http://144.217.164.110:12000/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{"teacher_id": "Test Teacher", "device_id": "test-device-123"}'
```
Response: Returns auth token successfully

---

### ❌ Failing Endpoint

**Debate Creation:**
```bash
curl -X POST http://144.217.164.110:12000/api/debates/create \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer <token>" \
  -d '{
    "motion": "Test motion",
    "format": "WSDC",
    "student_level": "secondary",
    "speech_time_seconds": 480,
    "teams": {
      "prop": [{"name": "Alice", "position": "Prop 1"}],
      "opp": [{"name": "Bob", "position": "Opp 1"}]
    }
  }'
```
Response: `{"error":{"message":"Internal server error","code":"INTERNAL_ERROR"}}`

---

## iOS App Configuration

### Current Configuration (Temporary Fix)

The app has been reverted to use the direct IP address:

**File**: `DebateFeedback/Utilities/Constants.swift`
**Line 14**: `static let baseURL = "http://144.217.164.110:12000/api"`

This bypasses the DNS issue but the backend debate creation still needs to be fixed.

---

## Required Backend Fixes

You need to check the backend server logs to see why debate creation is failing:

### 1. Check Backend Logs

```bash
# SSH into your VPS
ssh ubuntu@144.217.164.110

# Check backend logs
journalctl -u debate-feedback-backend -n 100 -f

# Look for errors when debate creation is attempted
```

### 2. Common Issues to Check

**Database Connection:**
- Is PostgreSQL running?
  ```bash
  sudo systemctl status postgresql
  ```

**Database Schema:**
- Does the `debates` table exist?
- Are all required columns present?
  ```bash
  sudo -u postgres psql debate_feedback -c "\d debates"
  ```

**Backend Code:**
- Is the `/api/debates/create` route properly implemented?
- Are there any missing fields or validation errors?
- Check the backend code for the debate creation handler

**Teacher ID:**
- The backend might be expecting a teacher UUID
- Check if the teacher record is being found correctly

---

## DNS Configuration (For HTTPS Later)

Once the backend is fixed, you'll need to configure DNS properly:

### Step 1: Check Current DNS

```bash
nslookup api.genalphai.com
dig api.genalphai.com
```

### Step 2: Update DNS Records

Go to your domain registrar (where you bought genalphai.com) and add:

**A Record:**
- **Name**: `api`
- **Type**: `A`
- **Value**: `144.217.164.110`
- **TTL**: `3600`

### Step 3: Wait for DNS Propagation

DNS changes can take 5 minutes to 48 hours to propagate globally.

### Step 4: Verify DNS

```bash
nslookup api.genalphai.com
# Should return: 144.217.164.110
```

### Step 5: Update iOS App

Once DNS is working, update `Constants.swift`:
```swift
static let baseURL = "https://api.genalphai.com/api"
```

---

## Debugging Steps for Backend

### 1. Test Individual Components

**Test database connection:**
```bash
sudo -u postgres psql debate_feedback -c "SELECT NOW();"
```

**Test if debates table exists:**
```bash
sudo -u postgres psql debate_feedback -c "SELECT COUNT(*) FROM debates;"
```

### 2. Check Backend Code

Look for the debate creation route handler. It should be handling:
- Teacher authentication ✅ (working)
- Request body parsing
- Team data validation
- Database insertion
- Response formatting

### 3. Check Error Logs

```bash
# Backend application logs
journalctl -u debate-feedback-backend -n 200

# Look for:
# - SQL errors
# - Validation errors
# - Missing field errors
# - Type conversion errors
```

### 4. Test with Minimal Data

Try creating a debate with minimal data to isolate the issue:

```bash
curl -X POST http://144.217.164.110:12000/api/debates/create \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer <token>" \
  -d '{
    "motion": "Test",
    "format": "WSDC",
    "student_level": "secondary",
    "speech_time_seconds": 480,
    "teams": {"prop": [], "opp": []}
  }'
```

---

## Temporary Workaround

Until the backend is fixed, the iOS app will fail when trying to create debates. The login works, but debate creation will show the error:

```
"Failed to create debate on server: resource not found"
```

or

```
"Failed to create debate on server: Internal server error"
```

---

## Action Items

### For Backend Developer:

1. **Fix debate creation endpoint** (CRITICAL)
   - Check backend logs for the actual error
   - Verify database schema matches backend expectations
   - Test endpoint manually with curl
   - Fix the internal server error

2. **Fix DNS configuration** (IMPORTANT)
   - Configure DNS A record for api.genalphai.com → 144.217.164.110
   - Verify SSL certificate is configured for the domain
   - Test HTTPS endpoint

3. **Test full flow:**
   - Login ✅
   - Create debate ❌ (needs fix)
   - Upload speech (untested until debate creation works)
   - Process feedback (untested)

### For iOS Developer:

1. **Wait for backend fixes**
   - App is correctly configured
   - Issue is on the backend side
   - No iOS changes needed at this time

2. **Test after backend fix:**
   - Login with "Test Teacher"
   - Create a debate
   - Verify debate creation succeeds
   - Test speech recording and upload

---

## Backend Error Investigation

The error message `Internal server error` is generic. You need to:

1. Enable debug logging on the backend
2. Check the actual error in the logs
3. Common causes:
   - Missing database column
   - Invalid data type conversion
   - Missing required field
   - Foreign key constraint failure (teacher_id not found)
   - JSON parsing error

---

## Expected Backend Behavior

When debate creation works, it should:

1. Receive the request with auth token
2. Validate the teacher's JWT token ✅ (this works)
3. Parse the request body
4. Validate the teams data
5. Insert into `debates` table
6. Return `{"debateId": "...", "debate_id": "...", "created_at": "..."}`

Currently it's failing at step 3, 4, or 5.

---

## Summary

**iOS App Status:** ✅ Correctly configured
**Backend Login:** ✅ Working
**Backend Debate Creation:** ❌ BROKEN - Returns 500 error
**DNS Configuration:** ❌ Points to Vercel instead of VPS

**Next Step:** Fix the backend debate creation endpoint by checking server logs and fixing the internal error.

---

**Created:** 2025-10-27
**Status:** Waiting for Backend Fix
**Priority:** HIGH - Blocks all testing
