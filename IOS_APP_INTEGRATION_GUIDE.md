# iOS App Integration Guide
## Debate Feedback App - Frontend Configuration

---

## 📡 **Backend Server Information**

### **VPS Server Details**
- **Public IP Address:** `144.217.164.110`
- **Backend Port:** `12000`
- **API Base URL:** `http://144.217.164.110:12000/api`

### **Available Endpoints**
| Endpoint | Method | Description |
|----------|--------|-------------|
| `/api/auth/login` | POST | Teacher login (email or teacher_id) |
| `/api/debates/create` | POST | Create new debate session |
| `/api/debates/:debateId/speeches` | POST | Upload speech recording |
| `/api/speeches/:id/status` | GET | Poll processing status |
| `/api/speeches/:id/feedback` | GET | Get feedback details |
| `/api/teachers/:teacherId/debates` | GET | Get debate history |
| `/api/schedule/current` | GET | Get current class schedule |
| `/api/health` | GET | Health check |

---

## 🎯 **iOS App Configuration Steps**

### **Step 1: Update API Base URL**

**File to Edit:** `DebateFeedback/Utilities/Constants.swift`

**Location:** Line 14

**Current Code:**
```swift
static let baseURL = "https://your-vps-domain.com/api"
```

**Change to:**
```swift
static let baseURL = "http://144.217.164.110:12000/api"
```

⚠️ **Important Notes:**
- Use `http://` (not `https://`) until SSL certificate is configured
- Port `12000` must be included in the URL
- Do NOT add a trailing slash

---

### **Step 2: Disable Mock Data Mode**

**File to Edit:** `DebateFeedback/Utilities/Constants.swift`

**Location:** Line 21

**Current Code:**
```swift
static var useMockData = true
```

**Change to:**
```swift
static var useMockData = false
```

This will enable real API calls instead of returning mock responses.

---

### **Step 3: Update App Transport Security (Optional)**

Since the backend is currently using HTTP (not HTTPS), you may need to allow insecure connections in development.

**File to Edit:** `DebateFeedback/Info.plist`

**Add this configuration:**
```xml
<key>NSAppTransportSecurity</key>
<dict>
    <key>NSAllowsArbitraryLoads</key>
    <false/>
    <key>NSExceptionDomains</key>
    <dict>
        <key>144.217.164.110</key>
        <dict>
            <key>NSExceptionAllowsInsecureHTTPLoads</key>
            <true/>
            <key>NSIncludesSubdomains</key>
            <true/>
        </dict>
    </dict>
</dict>
```

⚠️ **Security Note:** This is only for development. For production, use HTTPS with a valid SSL certificate.

---

## 🧪 **Testing the Connection**

### **Test 1: Backend Health Check**

Before testing the iOS app, verify the backend is running:

**From your computer/iOS device network:**
```bash
# In Terminal or using a web browser, visit:
http://144.217.164.110:12000/api/health

# Expected response:
{
  "status": "ok",
  "timestamp": "2025-10-27T...",
  "uptime": 1234,
  "memory": {...}
}
```

**If this fails:**
- Check if the backend server is running on the VPS
- Check if port 12000 is open in the firewall
- Verify your device can reach the IP address

---

### **Test 2: Test Login Endpoint**

**From iOS Simulator or Device:**

The iOS app will send this request when you enter a teacher name:

```json
POST http://144.217.164.110:12000/api/auth/login
Content-Type: application/json

{
  "teacher_id": "Test Teacher",
  "device_id": "ABC123-DEF456-GHI789"
}
```

**Expected Response:**
```json
{
  "token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
  "teacher": {
    "id": "550e8400-e29b-41d4-a716-446655440000",
    "name": "Test Teacher",
    "isAdmin": false
  }
}
```

---

### **Test 3: Test Debate Creation**

After login, the app will create debates:

```json
POST http://144.217.164.110:12000/api/debates/create
Authorization: Bearer <token>
Content-Type: application/json

{
  "motion": "This house believes...",
  "format": "WSDC",
  "student_level": "secondary",
  "speech_time_seconds": 480,
  "teams": {
    "prop": [{"name": "Alice", "position": "Prop 1"}],
    "opp": [{"name": "Bob", "position": "Opp 1"}]
  }
}
```

**Expected Response:**
```json
{
  "debateId": "660e8400-e29b-41d4-a716-446655440001",
  "debate_id": "660e8400-e29b-41d4-a716-446655440001",
  "created_at": "2025-10-27T12:34:56.789Z"
}
```

---

## 🔧 **Complete Code Changes Summary**

### **File 1: Constants.swift**

**Full file path:** `DebateFeedback/Utilities/Constants.swift`

**Changes needed:**
```swift
import Foundation

enum Constants {
    enum API {
        // ✅ CHANGE THIS LINE:
        static let baseURL = "http://144.217.164.110:12000/api"

        static let requestTimeout: TimeInterval = 30.0
        static let uploadTimeout: TimeInterval = 120.0
        static let maxRetryAttempts = 3
        static let feedbackPollingInterval: TimeInterval = 5.0

        // ✅ CHANGE THIS LINE:
        static var useMockData = false
    }

    // ... rest of the file remains unchanged
}
```

---

### **File 2: Info.plist (If needed)**

**Full file path:** `DebateFeedback/Info.plist`

**Add this section if you get network connection errors:**
```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <!-- Your existing keys here -->

    <!-- ✅ ADD THIS SECTION: -->
    <key>NSAppTransportSecurity</key>
    <dict>
        <key>NSExceptionDomains</key>
        <dict>
            <key>144.217.164.110</key>
            <dict>
                <key>NSExceptionAllowsInsecureHTTPLoads</key>
                <true/>
                <key>NSIncludesSubdomains</key>
                <true/>
            </dict>
        </dict>
    </dict>
</dict>
</plist>
```

---

## 🚀 **Running the iOS App**

### **Option 1: iOS Simulator (Easiest for Testing)**

1. Open `DebateFeedback.xcodeproj` in Xcode
2. Make the changes above to `Constants.swift`
3. Select an iPhone simulator (iPhone 15 Pro recommended)
4. Click Run (⌘R)
5. The app should launch in the simulator

**Network Access:** The simulator can access the VPS directly via the public IP.

---

### **Option 2: Physical iOS Device**

1. Connect your iPhone/iPad to your Mac via USB
2. Make the changes above to `Constants.swift`
3. Select your device in Xcode's device selector
4. Update the Info.plist with App Transport Security settings
5. Click Run (⌘R)
6. Xcode will install the app on your device

**Network Requirements:**
- Your iOS device must have internet access
- The device will connect to `144.217.164.110:12000`
- Ensure cellular data or WiFi is enabled

---

## 🔍 **Troubleshooting**

### **Issue 1: "Could not connect to the server"**

**Possible causes:**
- Backend server is not running on the VPS
- Port 12000 is blocked by firewall
- Network connectivity issue

**Solutions:**
1. Check backend is running: `systemctl status debate-feedback-backend`
2. Check port is open: `sudo ufw status` (should show port 12000)
3. Test from iOS device browser: Navigate to `http://144.217.164.110:12000/api/health`

---

### **Issue 2: "The resource could not be loaded because the App Transport Security policy requires the use of a secure connection"**

**Cause:** iOS blocks insecure HTTP connections by default.

**Solution:** Add the App Transport Security settings to Info.plist (see Step 3 above)

---

### **Issue 3: "Invalid credentials" on login**

**Cause:** No user exists in the database with that name.

**Solution:** Create a test user on the VPS:
```bash
# SSH into VPS
ssh ubuntu@144.217.164.110

# Connect to database
sudo -u postgres psql debate_feedback

# Insert test user
INSERT INTO users (email, name, role, institution)
VALUES ('test@school.com', 'Test Teacher', 'teacher', 'Test School');
```

---

### **Issue 4: Upload succeeds but never completes**

**Possible causes:**
- Worker process not running
- Redis not running
- AssemblyAI API key not configured

**Solutions:**
1. Check workers: `systemctl status debate-feedback-worker`
2. Check Redis: `redis-cli ping` (should return "PONG")
3. Check logs: `journalctl -u debate-feedback-backend -f`

---

### **Issue 5: Can't reach 144.217.164.110 from iOS device**

**Possible causes:**
- Firewall blocking the connection
- VPS provider network restrictions

**Solutions:**
1. Check firewall on VPS:
   ```bash
   sudo ufw status
   # Should show: 3000 ALLOW
   ```
2. Open port if needed:
   ```bash
   sudo ufw allow 3000/tcp
   ```

---

## 📱 **Testing Workflow**

### **Complete End-to-End Test**

1. **Launch the iOS app**
2. **Login Screen:**
   - Enter name: "Test Teacher" (must exist in database)
   - Tap "Start Session"
   - ✅ Should receive auth token and proceed

3. **Debate Setup:**
   - Enter motion: "This house believes technology does more harm than good"
   - Select format: WSDC
   - Select level: Secondary
   - Add students: Alice, Bob, Charlie, Diana
   - Assign to teams (Prop: Alice, Bob / Opp: Charlie, Diana)
   - Tap "Start Debate"
   - ✅ Backend should create debate record

4. **Recording:**
   - Tap microphone to start recording
   - Speak for 30-60 seconds
   - Tap stop
   - ✅ Upload progress should show
   - ✅ Upload should complete

5. **Processing:**
   - App polls status every 5 seconds
   - Status changes: pending → processing → complete
   - ✅ Google Doc URL should appear when complete (estimated 2-5 minutes)

6. **Feedback:**
   - Tap "View Feedback" when ready
   - ✅ Opens Google Doc in Safari

---

## 🔐 **Security Considerations**

### **Current Setup (Development)**
- ⚠️ HTTP (unencrypted)
- ⚠️ No SSL certificate
- ⚠️ IP-based access
- ✅ JWT authentication enabled
- ✅ CORS configured
- ✅ Rate limiting enabled

### **Production Recommendations**
1. **Get a domain name:** e.g., `api.debatefeedback.com`
2. **Configure SSL/TLS:** Use Let's Encrypt (free)
3. **Update to HTTPS:** Change baseURL to `https://api.debatefeedback.com/api`
4. **Remove ATS exception:** Remove Info.plist HTTP allowance
5. **Enable SSL pinning:** Add certificate pinning in iOS app
6. **Use Keychain:** Store auth token in iOS Keychain (not UserDefaults)

---

## 📊 **Backend Status Check Commands**

Run these on the VPS to verify backend health:

```bash
# Check backend service
systemctl status debate-feedback-backend

# Check worker service
systemctl status debate-feedback-worker

# Check recent logs
journalctl -u debate-feedback-backend -n 50

# Check if port 12000 is listening
sudo netstat -tlnp | grep 3000

# Check PostgreSQL
sudo systemctl status postgresql

# Check Redis
sudo systemctl status redis
redis-cli ping

# Test API manually
curl http://localhost:12000/api/health
```

---

## 🎯 **Quick Reference Card**

```
┌─────────────────────────────────────────────────────────────┐
│                 iOS APP CONFIGURATION                        │
├─────────────────────────────────────────────────────────────┤
│ Backend IP:    144.217.164.110                              │
│ Port:          12000                                          │
│ API Base URL:  http://144.217.164.110:12000/api              │
│                                                              │
│ File to Edit:  Constants.swift                               │
│ Line 14:       baseURL = "http://144.217.164.110:12000/api" │
│ Line 21:       useMockData = false                          │
│                                                              │
│ Optional:      Info.plist (add ATS exception)               │
└─────────────────────────────────────────────────────────────┘
```

---

## ✅ **Integration Checklist**

Before submitting your app for testing:

- [ ] Constants.swift updated with correct IP and port
- [ ] useMockData set to false
- [ ] Info.plist updated (if needed for HTTP)
- [ ] Backend server running on VPS
- [ ] Worker process running on VPS
- [ ] Port 12000 accessible from internet
- [ ] Test user created in database
- [ ] Tested login from iOS app
- [ ] Tested debate creation
- [ ] Tested speech recording and upload
- [ ] Tested feedback retrieval
- [ ] Verified Google Doc URLs open correctly

---

## 🆘 **Support & Debugging**

### **Backend Logs Location**
```
System Logs: journalctl -u debate-feedback-backend
App Logs:    /home/ubuntu/apps/feedback-backend/logs/combined.log
Error Logs:  /home/ubuntu/apps/feedback-backend/logs/error.log
```

### **iOS App Debugging**
- Enable Xcode console: View → Debug Area → Activate Console
- Network calls are logged in debug mode
- Check APIClient.swift for request/response logging

### **Common Error Codes**
| Code | Meaning | Solution |
|------|---------|----------|
| 400 | Bad Request | Check request body format |
| 401 | Unauthorized | Token invalid or expired, re-login |
| 404 | Not Found | Debate/speech ID doesn't exist |
| 500 | Server Error | Check backend logs |

---

## 📞 **Next Steps**

1. ✅ Make the two changes in Constants.swift
2. ✅ Add Info.plist configuration if needed
3. ✅ Build and run the iOS app
4. ✅ Test login with a teacher name that exists in the database
5. ✅ Create a debate and record a speech
6. ✅ Wait for processing (2-5 minutes)
7. ✅ View feedback in Google Docs

---

**Last Updated:** 2025-10-27
**Backend Version:** 1.0.0
**iOS App Version:** 1.0 (Build 1)
**Author:** Claude Code Assistant
