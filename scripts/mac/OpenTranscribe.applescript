-- Open Transcribe - macOS App Wrapper
-- This AppleScript creates a native macOS .app that launches and manages Open Transcribe

on run
	set appDir to POSIX path of (path to me) & "Contents/Resources/"
	set installScript to appDir & "scripts/mac/install.sh"
	set startScript to appDir & "scripts/mac/start.sh"
	set stopScript to appDir & "scripts/mac/stop.sh"
	set lockFile to appDir & ".pids/running.lock"
	
	-- Check if this is the first run (no venv exists)
	set venvPath to appDir & "backend/venv/"
	tell application "System Events"
		set isFirstRun to not (exists folder venvPath)
	end tell
	
	if isFirstRun then
		-- First run: show setup dialog and install dependencies
		set dialogMessage to "Welcome to Open Transcribe!" & return & return & "This will install the required dependencies:" & return & "• Python 3.12" & return & "• Node.js 20" & return & "• FFmpeg" & return & "• Python packages" & return & "• Node.js packages" & return & return & "This may take a few minutes."
		display dialog dialogMessage with title "Open Transcribe - First Run Setup" buttons {"Cancel", "Install"} default button "Install" with icon note
		
		if button returned of result is "Cancel" then
			return
		end if
		
		-- Run installer in Terminal
		tell application "Terminal"
			activate
			set shellCmd to "bash " & quoted form of POSIX path of installScript & " && echo '' && echo 'Press Enter to close this window and launch Open Transcribe...' && read && echo 'Starting Open Transcribe...' && bash " & quoted form of POSIX path of startScript & " --no-wait && exit 0"
			do script shellCmd
		end tell
		
		-- Wait a moment then open browser
		delay 15
		open location "http://localhost:5173"
	else
		-- Not first run: just start servers
		-- Check if already running
		try
			do shell script "curl -s http://localhost:8000/api/v1/health"
			-- Already running, just open browser
			open location "http://localhost:5173"
		on error
			-- Not running, start servers
			tell application "Terminal"
				activate
				set shellCmd to "bash " & quoted form of POSIX path of startScript & " --no-wait"
				do script shellCmd
			end tell
			delay 10
			open location "http://localhost:5173"
		end try
	end if
end run

on quit
	set appDir to POSIX path of (path to me) & "Contents/Resources/"
	set stopScript to appDir & "scripts/mac/stop.sh"
	
	-- Stop servers
	do shell script "bash " & quoted form of POSIX path of stopScript
	
	continue quit
end quit