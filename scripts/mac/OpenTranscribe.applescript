-- Open Transcribe - macOS App Wrapper
-- Opens pre-built .command files which macOS launches in Terminal automatically

on run
	set appDir to POSIX path of (path to me) & "Contents/Resources/"
	
	-- Check if first run by testing if venv directory exists
	set venvCheck to do shell script "if [ -d " & quoted form of (appDir & "backend/venv/") & " ]; then echo yes; else echo no; fi"
	
	if venvCheck is "no" then
		-- First run: open setup.command (installs deps + starts servers)
		do shell script "open " & quoted form of (appDir & "setup.command")
		delay 20
		open location "http://localhost:5173"
	else
		-- Not first run: check if already running
		set healthCheck to do shell script "curl -sf http://localhost:8000/api/v1/health || echo not-running"
		if healthCheck contains "ok" then
			open location "http://localhost:5173"
		else
			-- Not running, open start.command
			do shell script "open " & quoted form of (appDir & "start.command")
			delay 10
			open location "http://localhost:5173"
		end if
	end if
end run

on quit
	set appDir to POSIX path of (path to me) & "Contents/Resources/"
	do shell script "bash " & quoted form of (appDir & "scripts/mac/stop.sh")
	continue quit
end quit