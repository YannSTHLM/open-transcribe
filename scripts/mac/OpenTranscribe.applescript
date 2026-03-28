-- Open Transcribe - macOS App Wrapper
-- Uses .command files which macOS opens in Terminal automatically
-- Avoids "tell application Terminal" to prevent Automation permission errors

on run
	set appDir to POSIX path of (path to me) & "Contents/Resources/"
	set installScript to appDir & "scripts/mac/install.sh"
	set startScript to appDir & "scripts/mac/start.sh"
	
	-- Check if first run by testing if venv directory exists
	set venvCheck to do shell script "if [ -d " & quoted form of (appDir & "backend/venv/") & " ]; then echo yes; else echo no; fi"
	set isFirstRun to (venvCheck is "no")
	
	if isFirstRun then
		-- First run: create a .command file and open it in Terminal
		set tempFile to POSIX path of (path to temporary items) & "OpenTranscribe-Setup.command"
		set commandContent to "#!/bin/bash" & return & "echo 'Welcome to Open Transcribe!'" & return & "echo 'Installing dependencies...'" & return & "bash " & quoted form of installScript & " && echo '' && echo 'Setup complete! Starting Open Transcribe...' && bash " & quoted form of startScript
		
		-- Write .command file
		do shell script "cat > " & quoted form of tempFile & " << 'SCRIPT'" & return & commandContent & return & "SCRIPT"
		do shell script "chmod +x " & quoted form of tempFile
		
		-- Open the .command file (macOS opens .command files in Terminal)
		do shell script "open " & quoted form of tempFile
		
		-- Wait then open browser
		delay 20
		open location "http://localhost:5173"
	else
		-- Not first run: check if already running
		set healthCheck to do shell script "curl -s http://localhost:8000/api/v1/health 2>/dev/null || echo 'not-running'"
		if healthCheck contains "ok" then
			-- Already running, just open browser
			open location "http://localhost:5173"
		else
			-- Not running, create a .command file to start servers
			set tempFile to POSIX path of (path to temporary items) & "OpenTranscribe-Start.command"
			set commandContent to "#!/bin/bash" & return & "bash " & quoted form of startScript
			
			do shell script "cat > " & quoted form of tempFile & " << 'SCRIPT'" & return & commandContent & return & "SCRIPT"
			do shell script "chmod +x " & quoted form of tempFile
			do shell script "open " & quoted form of tempFile
			
			delay 10
			open location "http://localhost:5173"
		end if
	end if
end run

on quit
	set appDir to POSIX path of (path to me) & "Contents/Resources/"
	set stopScript to appDir & "scripts/mac/stop.sh"
	do shell script "bash " & quoted form of stopScript
	continue quit
end quit