' Open Transcribe - Windows Silent Launcher
' This VBS script launches the app without showing a command window
' Double-click this file or create a shortcut to it

Set fso = CreateObject("Scripting.FileSystemObject")
Set shell = CreateObject("WScript.Shell")

' Get the directory where this script is located
scriptDir = fso.GetParentFolderName(WScript.ScriptFullName)
appDir = fso.GetParentFolderName(fso.GetParentFolderName(scriptDir))

' Check if this is first run (no venv exists)
venvPath = appDir & "\backend\venv"

If Not fso.FolderExists(venvPath) Then
    ' First run - show installer
    shell.Run "powershell -ExecutionPolicy Bypass -NoExit -File """ & scriptDir & "\install.ps1""", 1, True
    
    ' After install, ask to start
    result = MsgBox("Setup complete! Start Open Transcribe now?", vbYesNo + vbQuestion, "Open Transcribe")
    If result = vbNo Then WScript.Quit
End If

' Start the servers
shell.Run "powershell -ExecutionPolicy Bypass -File """ & scriptDir & "\start.ps1""", 1, False