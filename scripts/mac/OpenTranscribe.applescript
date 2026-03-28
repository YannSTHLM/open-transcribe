-- Open Transcribe - macOS App Wrapper
-- Starts servers silently on launch, stops them on quit

on run
	set appDir to POSIX path of (path to me) & "Contents/Resources/"
	
	-- Check if first run by testing if setup completed successfully
	set setupCheck to do shell script "if [ -f " & quoted form of (appDir & "backend/.setup-complete") & " ]; then echo yes; else echo no; fi"
	
	if setupCheck is "no" then
		-- First run: open setup.command (installs deps + starts servers)
		-- This one DOES need Terminal for the user to see progress
		do shell script "open " & quoted form of (appDir & "setup.command")
		delay 20
		open location "http://localhost:5173"
	else
		-- Not first run: check if already running
		try
			set healthCheck to do shell script "curl -sf http://localhost:8000/api/v1/health"
			-- Already running, just open browser
			open location "http://localhost:5173"
		on error
			-- Not running: start servers silently (no Terminal window)
			do shell script "bash " & quoted form of (appDir & "scripts/mac/start.sh") & " --daemon"
			
			-- Wait for backend to be ready (max 30s)
			repeat with i from 1 to 30
				try
					do shell script "curl -sf http://localhost:8000/api/v1/health"
					exit repeat
				on error
					delay 1
				end try
			end repeat
			
			-- Open browser
			open location "http://localhost:5173"
		end try
	end if
end run

on quit
	set appDir to POSIX path of (path to me) & "Contents/Resources/"
	-- Stop servers silently
	try
		do shell script "bash " & quoted form of (appDir & "scripts/mac/stop.sh")
	end try
	continue quit
end quit