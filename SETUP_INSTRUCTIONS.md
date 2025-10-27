Setup Instructions
Critical: Microphone Permission Setup
Before running the app, you MUST add microphone permission to the project:
Method 1: Using Xcode UI (Recommended)
	•	Open DebateFeedback.xcodeproj in Xcode
	•	Select the DebateFeedback target in the project navigator
	•	Go to the Info tab
	•	Under "Custom iOS Target Properties", click the + button
	•	Add this entry:
	•	Key: Privacy - Microphone Usage Description (or NSMicrophoneUsageDescription)
	•	Type: String
	•	Value: We need access to the microphone to record debate speeches.
Method 2: Edit Info.plist Directly
If your project has an Info.plist file:

	•	Open DebateFeedback/Info.plist
	•	Add this XML:

<key>NSMicrophoneUsageDescription</key>

<string>We need access to the microphone to record debate speeches.</string>
Backend Configuration
1. Mock Mode (Development - No Backend Needed)
The app ships with mock mode enabled for testing:

// In Utilities/Constants.swift

enum API {

    static let useMockData = true  // Already set to true

}

With mock mode:

	•	All API calls return simulated data
	•	Uploads show progress but don't hit real servers
	•	Feedback polling returns mock Google Docs URLs
	•	Perfect for UI/UX testing
2. Production Mode (With Backend)
When your backend is ready:

// In Utilities/Constants.swift

enum API {

    static let baseURL = "https://your-backend.com/api"  // Update this

    static let useMockData = false  // Change to false

}
Optional: Bell Sound Files
The app works without these, but for authentic bell sounds:

	•	Create folder: DebateFeedback/Resources/Sounds
	•	Add these files:
	•	bell_1.mp3 - Single bell sound
	•	bell_2.mp3 - Double bell sound
	•	bell_3.mp3 - Triple bell sound
	•	Drag files into Xcode
	•	Ensure "Add to targets" checkbox is checked for DebateFeedback

Currently, the app uses system sounds as fallback.
Running the App
On Simulator
# Open in Xcode

open DebateFeedback.xcodeproj

# Or from command line

xcodebuild -project DebateFeedback.xcodeproj -scheme DebateFeedback -destination 'platform=iOS Simulator,name=iPhone 15 Pro'

Note: Audio recording may not work properly on simulator. Use a real device for full testing.
On Physical Device
	•	Connect your iPhone/iPad
	•	Select your device in Xcode's device menu
	•	Sign the app with your Apple ID:
	•	Go to Signing & Capabilities tab
	•	Check "Automatically manage signing"
	•	Select your Team (Personal Team is fine)
	•	Press ⌘R to build and run
Testing Workflow
1. First Launch Test
	•	Launch app
	•	Should see microphone permission alert
	•	Tap "Allow"
	•	Should reach authentication screen
2. Guest Mode Test
	•	Tap "Continue as Guest"
	•	Enter motion: "This house believes that social media does more harm than good"
	•	Select format: WSDC
	•	Add students: Alice, Bob, Carol, Dave, Eve, Frank
	•	Drag students to teams (3 Prop, 3 Opp)
	•	Tap "Start Debate"
	•	Tap START - timer should run, REC indicator should show
	•	Speak for ~30 seconds
	•	Tap STOP - should auto-upload (progress bar) and move to next speaker
	•	Complete all 6 speeches
	•	Tap "View Feedback"
	•	Should see all speeches with mock Google Docs links
3. Teacher Mode Test
	•	Logout from guest mode
	•	Enter teacher name: "Mr. Smith"
	•	Tap "Login as Teacher"
	•	Follow same debate setup flow
	•	Note: Debates are saved to history (unlike guest mode)
Common Issues
❌ "Microphone permission denied"
Fix:

	•	Go to iPhone Settings → Privacy & Security → Microphone
	•	Enable DebateFeedback
	•	Restart app
❌ "Failed to start recording"
Causes:

	•	Permission not added to Info.plist → Add it
	•	Another app using microphone → Close other apps
	•	Running on simulator → Use real device
❌ "Invalid recording file"
Fix: Ensure using real device, not simulator
❌ Upload shows "Failed"
Check:

	•	Is useMockData = true? Should succeed in mock mode
	•	Is backend URL correct?
	•	Is internet connected?
	•	Check backend logs
Project Status
✅ Complete & Working
	•	Authentication (Teacher + Guest)
	•	Debate setup wizard (3 steps)
	•	Drag & drop team assignment
	•	Timer with 60fps precision
	•	Audio recording (M4A @ 128kbps)
	•	Background upload with retry
	•	Feedback viewing with share
	•	SwiftData persistence
	•	Mock mode for testing
🚧 To Be Added (Phase 7)
	•	Auto-population from schedule API
	•	History view for past debates
	•	iPad-optimized layout
	•	Real bell sound files
	•	Swipe gestures for navigation
	•	Offline upload queue
File Locations
After running the app, files are stored at:

/Users/[username]/Library/Developer/CoreSimulator/Devices/[device-id]/data/Containers/Data/Application/[app-id]/Documents/Recordings/

Format: {debate_id}_{speaker_name}_{position}_{timestamp}.m4a

Example: abc123_alice_smith_prop1_20250124153045.m4a
Next Steps
	•	Add microphone permission (REQUIRED)
	•	Run app on real device
	•	Test full debate flow
	•	When backend ready, update API baseURL and set useMockData = false
	•	Add bell sound files (optional)
	•	Deploy to TestFlight or App Store
Quick Command Reference
# Build for simulator

xcodebuild -project DebateFeedback.xcodeproj -scheme DebateFeedback -sdk iphonesimulator

# Build for device

xcodebuild -project DebateFeedback.xcodeproj -scheme DebateFeedback -sdk iphoneos

# Run tests (when tests are added)

xcodebuild test -project DebateFeedback.xcodeproj -scheme DebateFeedback -destination 'platform=iOS Simulator,name=iPhone 15 Pro'

# Clean build

xcodebuild clean -project DebateFeedback.xcodeproj -scheme DebateFeedback



Ready to build! 🚀

Open DebateFeedback.xcodeproj in Xcode, add microphone permission, and press ⌘R.

