Quick Start Guide
🚀 Get Running in 5 Minutes
Step 1: Add Microphone Permission (REQUIRED)
	•	Open DebateFeedback.xcodeproj in Xcode
	•	Select DebateFeedback target
	•	Click Info tab
	•	Click + button
	•	Add:
	•	Key: Privacy - Microphone Usage Description
	•	Value: We need access to the microphone to record debate speeches.
Step 2: Run on Device
	•	Connect your iPhone/iPad via USB
	•	Select your device in Xcode (top bar)
	•	Signing & Capabilities tab → Enable "Automatically manage signing"
	•	Select your Team (Apple ID)
	•	Press ⌘R to build and run
Step 3: Test the App
	•	Launch → Allow microphone permission
	•	Login → Tap "Continue as Guest"
	•	Setup →
	•	Motion: "This house believes that social media does more harm than good"
	•	Format: WSDC
	•	Add 6 students (any names)
	•	Drag 3 to Prop, 3 to Opp
	•	Debate →
	•	Tap START (speak for 10-20 seconds)
	•	Tap STOP
	•	Repeat for all 6 speakers (or skip ahead with Next button)
	•	Feedback →
	•	Tap "View Feedback"
	•	See mock Google Docs links


⚙️ Configuration
Backend URL (when ready)
Edit Utilities/Constants.swift:

enum API {

    static let baseURL = "https://your-backend.com/api"  // Update this

    static let useMockData = false  // Change to false

}
Current State
	•	✅ Mock mode enabled (works without backend)
	•	✅ All features functional
	•	⚠️ Using system sounds for bells (add MP3 files for custom sounds)


📱 Supported Devices
	•	iPhone running iOS 17+
	•	iPad running iOS 17+
	•	Note: Simulator audio recording doesn't work well - use real device


🐛 Troubleshooting
"Microphone permission denied"
→ Add to Info.plist (see Step 1 above)
"Code signing error"
→ Go to Signing & Capabilities → Select your Team
"Recording failed"
→ Test on real device (not simulator)
Bells not working
→ Normal - add bell_1.mp3, bell_2.mp3, bell_3.mp3 to Resources/Sounds/


📚 Documentation
	•	README.md - Complete guide
	•	SETUP_INSTRUCTIONS.md - Detailed setup
	•	PROJECT_SUMMARY.md - What was built
	•	DEBATE_FORMATS.md - Format reference


✅ What Works Right Now
	•	Teacher and Guest login
	•	3-step debate setup wizard
	•	Drag & drop team assignment
	•	4 debate formats (WSDC, BP, AP, Australs)
	•	Timer with 60fps precision
	•	Audio recording (M4A)
	•	Background upload with progress
	•	Feedback viewing with Google Docs links
	•	Share functionality
	•	Full mock mode (no backend needed)


🎯 Next Steps
	•	✅ Add microphone permission
	•	✅ Run on device
	•	✅ Test full flow
	•	⏳ Connect backend
	•	⏳ Add bell sounds (optional)
	•	⏳ Deploy to TestFlight



That's it! You now have a fully functional debate recording app.

For questions or issues, see the full README.md.

