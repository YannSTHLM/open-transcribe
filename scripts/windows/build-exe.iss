; Open Transcribe - Inno Setup Installer Configuration
; Build with: iscc build-exe.iss
; Requires: Inno Setup (https://jrsoftware.org/isinfo.php)
;
; This creates OpenTranscribe-Setup.exe which:
; 1. Installs the project files to Program Files
; 2. Creates Start Menu shortcuts
; 3. Creates a desktop shortcut
; 4. On first launch, the VBS launcher runs install.ps1 to download dependencies

[Setup]
AppName=Open Transcribe
AppVersion=1.0.0
AppPublisher=Open Transcribe
AppPublisherURL=https://github.com/YannSTHLM/open-transcribe
AppSupportURL=https://github.com/YannSTHLM/open-transcribe/issues
DefaultDirName={autopf}\Open Transcribe
DefaultGroupName=Open Transcribe
UninstallDisplayIcon={app}\scripts\windows\launcher.vbs
OutputDir=..\..\build
OutputBaseFilename=OpenTranscribe-Setup-Windows
Compression=lzma2/ultra64
SolidCompression=yes
WizardStyle=modern
PrivilegesRequired=admin
SetupIconFile=..\..\assets\icon.ico
; Uncomment the next line if you have a license file
; LicenseFile=..\..\LICENSE

[Languages]
Name: "english"; MessagesFile: "compiler:Default.isl"

[Tasks]
Name: "desktopicon"; Description: "Create a &desktop shortcut"; GroupDescription: "Additional icons:"

[Files]
; Backend
Source: "..\..\backend\*"; DestDir: "{app}\backend"; Flags: ignoreversion recursesubdirs; Excludes: "venv\*,__pycache__\*,*.pyc,data\*,.env"

; Frontend (source code only - npm install runs on first launch)
Source: "..\..\frontend\*"; DestDir: "{app}\frontend"; Flags: ignoreversion recursesubdirs; Excludes: "node_modules\*,dist\*"

; Scripts
Source: "install.ps1"; DestDir: "{app}\scripts\windows"; Flags: ignoreversion
Source: "start.ps1"; DestDir: "{app}\scripts\windows"; Flags: ignoreversion
Source: "stop.ps1"; DestDir: "{app}\scripts\windows"; Flags: ignoreversion
Source: "launcher.vbs"; DestDir: "{app}\scripts\windows"; Flags: ignoreversion

; README
Source: "..\..\README.md"; DestDir: "{app}"; Flags: ignoreversion

[Icons]
Name: "{group}\Open Transcribe"; Filename: "wscript.exe"; Parameters: """{app}\scripts\windows\launcher.vbs"""; WorkingDir: "{app}"; Comment: "Launch Open Transcribe"
Name: "{group}\Stop Servers"; Filename: "powershell.exe"; Parameters: "-ExecutionPolicy Bypass -File ""{app}\scripts\windows\stop.ps1"""; WorkingDir: "{app}"; Comment: "Stop Open Transcribe servers"
Name: "{group}\Uninstall Open Transcribe"; Filename: "{uninstallexe}"
Name: "{autodesktop}\Open Transcribe"; Filename: "wscript.exe"; Parameters: """{app}\scripts\windows\launcher.vbs"""; WorkingDir: "{app}"; Tasks: desktopicon

[Run]
Filename: "wscript.exe"; Parameters: """{app}\scripts\windows\launcher.vbs"""; Description: "&Launch Open Transcribe"; Flags: nowait postinstall skipifsilent

[UninstallRun]
; Stop servers before uninstalling
Filename: "powershell.exe"; Parameters: "-ExecutionPolicy Bypass -File ""{app}\scripts\windows\stop.ps1"""; Flags: runhidden