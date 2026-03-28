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
        display dialog "Welcome to Open Transcribe! 🎙️\n\nThis will install the required dependencies:\n• Python 3.12\n• Node.js 20\n• FFmpeg\n• Python packages\n• Node.js packages\n\nThis may take a few minutes." with title "Open Transcribe - First Run Setup" buttons {"Cancel", "Install"} default button "Install" with icon note
        
        if button returned of result is "Cancel" then
            return
        end if
        
        -- Run installer in Terminal
        tell application "Terminal"
            activate
            do script "bash '" & installScript & "' && echo '' && echo 'Press Enter to close this window and launch Open Transcribe...' && read && echo 'Starting Open Transcribe...' && bash '" & startScript & "' --no-wait && exit 0"
        end tell
        
        -- Wait a moment then open browser
        delay 15
        openLocation "http://localhost:5173"
    else
        -- Not first run: just start servers
        -- Check if already running
        try
            do shell script "curl -s http://localhost:8000/api/v1/health"
            -- Already running, just open browser
            openLocation "http://localhost:5173"
        on error
            -- Not running, start servers
            tell application "Terminal"
                activate
                do script "bash '" & startScript & "' --no-wait"
            end tell
            delay 10
            openLocation "http://localhost:5173"
        end try
    end if
end run

on quit
    set appDir to POSIX path of (path to me) & "Contents/Resources/"
    set stopScript to appDir & "scripts/mac/stop.sh"
    
    -- Stop servers
    do shell script "bash '" & stopScript & "'"
    
    continue quit
end quit