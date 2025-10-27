Format Updates
Changes Made
WSDC Format Corrections ✅
Previous (Incorrect):

	•	WSDC: 5 min speeches, 3 min reply

Updated (Correct):

	•	WSDC: 8 min speeches, 4 min reply
	•	Modified WSDC (4min): 4 min speeches, 2 min reply
	•	Modified WSDC (5min available via manual time adjustment)
Implementation Details
Code Changes:
	•	DebateSession.swift - Updated DebateFormat enum:

	•	WSDC default: 8 min → 4 min reply
	•	Added modifiedWsdc case: 4 min → 2 min reply
	•	Both use 3v3 Prop/Opp structure

	•	Constants.swift - Updated format list:

	•	Added .modifiedWsdc to available formats

	•	DEBATE_FORMATS.md - Updated documentation:

	•	Corrected all WSDC timings
	•	Added Modified WSDC section
	•	Updated bell timings to match
UI Impact:
	•	Format picker now shows 5 options:

	•	WSDC (8/4)
	•	Modified WSDC (4/2)
	•	BP (7/none)
	•	AP (6/none)
	•	Australs (8/3)

	•	Users can still manually adjust times after selecting a format
Bell Timings:
	•	WSDC: 1:00, 7:00, 8:00, +15s
	•	Modified WSDC: 1:00, 3:00, 4:00, +15s
	•	BP: 1:00, 6:00, 7:00, +15s
	•	AP: 1:00, 5:00, 6:00, +15s
	•	Australs: 1:00, 7:00, 8:00, +15s
Testing
To test the new format:

	•	Run app
	•	Setup debate
	•	Select "Modified WSDC" from format picker
	•	Verify default times: 4 min speech, 2 min reply
	•	Proceed with debate
	•	Verify bells at 1:00, 3:00, 4:00
Flexibility
Users can create a "5 minute WSDC" by:

	•	Select "WSDC" or "Modified WSDC"
	•	Manually adjust speech time to 5 min
	•	Manually adjust reply time to 3 min
	•	Bells will auto-adjust: 1:00, 4:00, 5:00, +15s

This gives maximum flexibility while providing sensible defaults.



Date: 2025-01-24 Files Modified: 3 Status: Complete ✅

