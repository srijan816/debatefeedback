How to Add Microphone Permission
Method 1: Using Xcode UI (Recommended)
Step-by-Step Instructions:
	•	Open the project in Xcode:

open DebateFeedback.xcodeproj

	•	Select the target:

	•	In the left sidebar (Project Navigator), click on the DebateFeedback project (blue icon at the top)
	•	In the center panel under "TARGETS", select DebateFeedback

	•	Go to Info tab:

	•	Click the Info tab at the top (next to "General", "Signing & Capabilities")

	•	Add the permission:

	•	Look for the section "Custom iOS Target Properties"
	•	Click the + button (or right-click and select "Add Row")
	•	In the dropdown that appears, start typing: "Privacy - Microphone"
	•	Select: "Privacy - Microphone Usage Description"
	•	In the "Value" column, paste this text:

We need access to the microphone to record debate speeches.

	•	Verify:

	•	You should now see a row that looks like:

Privacy - Microphone Usage Description | String | We need access to the microphone to record debate speeches.

	•	Build:

	•	Press ⌘B to build (should succeed)


Method 2: If You Can't Find the Key
If you can't find "Privacy - Microphone Usage Description" in the dropdown:

	•	Follow steps 1-3 above
	•	Click the + button
	•	Type the raw key name exactly: NSMicrophoneUsageDescription
	•	Press Enter/Return
	•	Change the Type to String (if it's not already)
	•	Set the Value to: We need access to the microphone to record debate speeches.


Method 3: Create Info.plist File (Alternative)
If the above methods don't work:

	•	In Xcode, right-click on the DebateFeedback folder (yellow folder in left sidebar)
	•	Select New File...
	•	Choose Property List under "Resource"
	•	Name it Info.plist
	•	Make sure it's added to the DebateFeedback target (checkbox)
	•	Click Create
	•	Right-click on the new Info.plist file
	•	Select Open As → Source Code
	•	Replace the contents with:

<?xml version="1.0" encoding="UTF-8"?>

<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">

<plist version="1.0">

<dict>

    <key>NSMicrophoneUsageDescription</key>

    <string>We need access to the microphone to record debate speeches.</string>

</dict>

</plist>

	•	Save the file (⌘S)
	•	Clean build folder (⌘⇧K)
	•	Build (⌘B)


Verification
After adding the permission:

	•	Build the project (⌘B) - should succeed
	•	Run on a device (⌘R)
	•	When you first try to record, you should see a system alert that says:

"DebateFeedback" Would Like to Access the Microphone

We need access to the microphone to record debate speeches.

[Don't Allow]  [OK]

If you see this alert, the permission is correctly configured! ✅


Troubleshooting
"Can't find the key in dropdown"
	•	Use the raw key name: NSMicrophoneUsageDescription
	•	Make sure you're in the Info tab, not "Build Settings"
"Still getting permission error"
	•	Clean build folder: ⌘⇧K
	•	Delete app from device/simulator
	•	Build and run again
"I don't see 'Custom iOS Target Properties'"
	•	Make sure you're viewing the target's Info tab, not the project's
	•	The target is under "TARGETS" section, not "PROJECT" section


Quick Visual Guide
Where to find things:

Xcode Window

├── Left Sidebar (Project Navigator)

│   └── DebateFeedback (blue icon) ← Click this

│

├── Center Panel

│   ├── PROJECT: DebateFeedback ← Not this

│   └── TARGETS: DebateFeedback ← Click this!

│

└── Top Tabs

    ├── General

    ├── Signing & Capabilities

    ├── Resource Tags

    ├── Info ← Click this!

    ├── Build Settings

    └── Build Phases

In the Info tab, look for a section with rows like:

Key                                    | Type   | Value

---------------------------------------|--------|------------------

Bundle name                            | String | $(PRODUCT_NAME)

Bundle identifier                      | String | com.yourapp...

Privacy - Microphone Usage Description | String | We need access...  ← Add this


After Adding Permission
Once the permission is added:

	•	Build (⌘B) - Should succeed ✅
	•	Run (⌘R) on a real device
	•	Test the app:
	•	Login as Guest
	•	Setup debate
	•	Tap START
	•	Grant microphone permission when prompted
	•	Recording should work!



If you're still having trouble, let me know and I can provide alternative solutions!

