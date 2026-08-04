#define MyAppName "Markplane MCP for Agents"
#define MyAppVersion "0.1.2"
#define MyAppPublisher "Local"
#define MyAppExeName "markplane.exe"

[Setup]
AppId={{6B7A3265-A262-4604-9D44-E022615682B7}
AppName={#MyAppName}
AppVersion={#MyAppVersion}
AppPublisher={#MyAppPublisher}
DefaultDirName={localappdata}\Programs\Markplane
DefaultGroupName=Markplane
DisableProgramGroupPage=yes
PrivilegesRequired=lowest
OutputDir=Output
OutputBaseFilename=MarkplaneAgentSetup-{#MyAppVersion}
Compression=lzma2
SolidCompression=yes
WizardStyle=modern
UninstallDisplayIcon={app}\{#MyAppExeName}
ArchitecturesAllowed=x64compatible
ArchitecturesInstallIn64BitMode=x64compatible

[Languages]
Name: "english"; MessagesFile: "compiler:Default.isl"

[Files]
Source: "markplane.exe"; DestDir: "{app}"; Flags: ignoreversion
Source: "Install-MarkplaneForAgents.ps1"; DestDir: "{app}"; Flags: ignoreversion
Source: "Install-VSCodeExtension.ps1"; DestDir: "{app}"; Flags: ignoreversion
Source: "Configure-ClaudeCode.ps1"; DestDir: "{app}"; Flags: ignoreversion
Source: "Install-MarkplaneAgentSkills.ps1"; DestDir: "{app}"; Flags: ignoreversion
Source: "Install-AntigravityIntegration.ps1"; DestDir: "{app}"; Flags: ignoreversion
Source: "Install-AntigravityWorkspace.ps1"; DestDir: "{app}"; Flags: ignoreversion
Source: "Test-MarkplaneAgentSkills.ps1"; DestDir: "{app}"; Flags: ignoreversion
Source: "Install-ClaudeCodeHooks.ps1"; DestDir: "{app}"; Flags: ignoreversion
Source: "research-checkpoint-agents-extension.txt"; DestDir: "{app}"; Flags: ignoreversion
Source: "skills\*"; DestDir: "{app}\skills"; Flags: ignoreversion recursesubdirs createallsubdirs
Source: "agent-config-templates\*"; DestDir: "{app}\agent-config-templates"; Flags: ignoreversion recursesubdirs createallsubdirs
Source: "vscode-extension\markplane-vscode-0.1.2.vsix"; DestDir: "{app}\vscode-extension"; Flags: ignoreversion
Source: "hooks\*"; DestDir: "{app}\hooks"; Flags: ignoreversion recursesubdirs createallsubdirs
; Antigravity hook entrypoint: Invoke-MarkplaneAntigravityHook.ps1

[Run]
Filename: "powershell.exe"; Parameters: "-NoProfile -ExecutionPolicy Bypass -File ""{app}\Install-MarkplaneForAgents.ps1"" -InstallDir ""{app}"""; Description: "Install Markplane and update user PATH"; Flags: runhidden waituntilterminated
Filename: "powershell.exe"; Parameters: "-NoProfile -ExecutionPolicy Bypass -File ""{app}\Configure-ClaudeCode.ps1"" -Scope user -MarkplaneExe ""{app}\markplane.exe"""; Description: "Configure Claude Code MCP integration"; Flags: runhidden waituntilterminated
Filename: "powershell.exe"; Parameters: "-NoProfile -ExecutionPolicy Bypass -File ""{app}\Install-MarkplaneAgentSkills.ps1"" -SkillSourceRoot ""{app}\skills"" -AgentsHintPath ""{app}\research-checkpoint-agents-extension.txt"""; Description: "Install Markplane research skills for Codex and Claude Code"; Flags: runhidden waituntilterminated
Filename: "powershell.exe"; Parameters: "-NoProfile -ExecutionPolicy Bypass -File ""{app}\Install-ClaudeCodeHooks.ps1"" -InstallDir ""{app}"""; Description: "Install Markplane Claude Code hooks"; Flags: runhidden waituntilterminated
Filename: "powershell.exe"; Parameters: "-NoProfile -ExecutionPolicy Bypass -File ""{app}\Install-AntigravityIntegration.ps1"" -InstallDir ""{app}"" -SkillSourceRoot ""{app}\skills"" -AgentsHintPath ""{app}\research-checkpoint-agents-extension.txt"""; Description: "Configure Antigravity Gemini integration"; Flags: runhidden waituntilterminated
Filename: "powershell.exe"; Parameters: "-NoProfile -ExecutionPolicy Bypass -File ""{app}\Install-VSCodeExtension.ps1"" -VsixPath ""{app}\vscode-extension\markplane-vscode-0.1.2.vsix"" -ShowSummary"; Description: "Install Markplane VS Code and Antigravity IDE integration"; Flags: runhidden waituntilterminated

[UninstallRun]
Filename: "powershell.exe"; Parameters: "-NoProfile -ExecutionPolicy Bypass -File ""{app}\Install-MarkplaneForAgents.ps1"" -Uninstall -InstallDir ""{app}"""; Flags: runhidden waituntilterminated; RunOnceId: "RemoveMarkplaneAgentPathIntegration"
Filename: "powershell.exe"; Parameters: "-NoProfile -ExecutionPolicy Bypass -File ""{app}\Install-ClaudeCodeHooks.ps1"" -Uninstall -InstallDir ""{app}"""; Flags: runhidden waituntilterminated; RunOnceId: "RemoveMarkplaneClaudeHooks"
Filename: "powershell.exe"; Parameters: "-NoProfile -ExecutionPolicy Bypass -File ""{app}\Install-MarkplaneAgentSkills.ps1"" -Uninstall"; Flags: runhidden waituntilterminated; RunOnceId: "RemoveMarkplaneResearchSkills"
Filename: "powershell.exe"; Parameters: "-NoProfile -ExecutionPolicy Bypass -File ""{app}\Install-AntigravityIntegration.ps1"" -Uninstall -InstallDir ""{app}"""; Flags: runhidden waituntilterminated; RunOnceId: "RemoveMarkplaneAntigravityIntegration"
Filename: "powershell.exe"; Parameters: "-NoProfile -ExecutionPolicy Bypass -File ""{app}\Install-VSCodeExtension.ps1"" -Uninstall"; Flags: runhidden waituntilterminated; RunOnceId: "RemoveMarkplaneVSCodeIntegration"

[Code]
function IsClaudeCliAvailable(): Boolean;
var
  ResultCode: Integer;
begin
  Result := Exec('cmd.exe', '/C where claude >nul 2>nul', '', SW_HIDE, ewWaitUntilTerminated, ResultCode) and (ResultCode = 0);
end;

procedure CurStepChanged(CurStep: TSetupStep);
begin
  if (CurStep = ssPostInstall) and (not IsClaudeCliAvailable()) then
  begin
    MsgBox('The Claude Code CLI (''claude'') was not found on PATH, so the Markplane MCP server could not be registered automatically.' + #13#10 + #13#10 +
      'Install Claude Code, then run:' + #13#10 +
      '  claude mcp add --transport stdio --scope user markplane -- markplane mcp' + #13#10 + #13#10 +
      'to finish the integration.', mbInformation, MB_OK);
  end;
end;


