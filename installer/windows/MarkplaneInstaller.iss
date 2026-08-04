#define MyAppName "Research With Coding Agents"
#define MyAppVersion "0.1.0"
#define MyAppPublisher "Research With Coding Agents"
#define MyAppExeName "markplane.exe"

[Setup]
AppId={{7E8F1C7D-1F1C-4F46-B5B1-5D533ED40A2B}
AppName={#MyAppName}
AppVersion={#MyAppVersion}
AppPublisher={#MyAppPublisher}
DefaultDirName={localappdata}\Programs\ResearchWithCodingAgents
DefaultGroupName=Research With Coding Agents
DisableProgramGroupPage=yes
PrivilegesRequired=lowest
OutputDir=Output
OutputBaseFilename=ResearchWithCodingAgentsSetup-v0.1.0
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
Source: "Install-MarkplaneForCodex.ps1"; DestDir: "{app}"; Flags: ignoreversion
Source: "Install-VSCodeExtension.ps1"; DestDir: "{app}"; Flags: ignoreversion
Source: "Configure-ClaudeCode.ps1"; DestDir: "{app}"; Flags: ignoreversion
Source: "Install-ClaudeCodeHooks.ps1"; DestDir: "{app}"; Flags: ignoreversion
Source: "Install-CodexHooks.ps1"; DestDir: "{app}"; Flags: ignoreversion
Source: "Install-MarkplaneAgentSkills.ps1"; DestDir: "{app}"; Flags: ignoreversion
Source: "Install-AntigravityIntegration.ps1"; DestDir: "{app}"; Flags: ignoreversion
Source: "Install-AntigravityWorkspace.ps1"; DestDir: "{app}"; Flags: ignoreversion
Source: "Test-MarkplaneAgentSkills.ps1"; DestDir: "{app}"; Flags: ignoreversion
Source: "research-checkpoint-agents-extension.txt"; DestDir: "{app}"; Flags: ignoreversion
Source: "..\..\components\superpowers\skills\*"; DestDir: "{app}\skills"; Flags: ignoreversion recursesubdirs createallsubdirs
Source: "markplane-agents-extension.txt"; DestDir: "{app}"; Flags: ignoreversion
Source: "vscode-extension\markplane-vscode-0.1.2.vsix"; DestDir: "{app}\vscode-extension"; Flags: ignoreversion
Source: "..\..\packages\agent-adapters\hooks\*"; DestDir: "{app}\hooks"; Flags: ignoreversion recursesubdirs createallsubdirs
; Antigravity hook entrypoint: Invoke-MarkplaneAntigravityHook.ps1

[Run]
Filename: "powershell.exe"; Parameters: "-NoProfile -ExecutionPolicy Bypass -File ""{app}\Install-MarkplaneForCodex.ps1"" -InstallDir ""{app}"" -AgentsExtensionPath ""{app}\markplane-agents-extension.txt"""; Description: "Configure PATH and Codex MCP integration"; Flags: runhidden waituntilterminated
Filename: "powershell.exe"; Parameters: "-NoProfile -ExecutionPolicy Bypass -File ""{app}\Configure-ClaudeCode.ps1"" -Scope user -MarkplaneExe ""{app}\markplane.exe"""; Description: "Configure Claude Code MCP integration"; Flags: runhidden waituntilterminated
Filename: "powershell.exe"; Parameters: "-NoProfile -ExecutionPolicy Bypass -File ""{app}\Install-MarkplaneAgentSkills.ps1"" -SkillSourceRoot ""{app}\skills"" -AgentsHintPath ""{app}\research-checkpoint-agents-extension.txt"""; Description: "Install Markplane research skills for Codex and Claude Code"; Flags: runhidden waituntilterminated
Filename: "powershell.exe"; Parameters: "-NoProfile -ExecutionPolicy Bypass -File ""{app}\Install-ClaudeCodeHooks.ps1"" -InstallDir ""{app}"""; Description: "Install Markplane Claude Code hooks"; Flags: runhidden waituntilterminated
Filename: "powershell.exe"; Parameters: "-NoProfile -ExecutionPolicy Bypass -File ""{app}\Install-AntigravityIntegration.ps1"" -InstallDir ""{app}"" -SkillSourceRoot ""{app}\skills"" -AgentsHintPath ""{app}\research-checkpoint-agents-extension.txt"""; Description: "Configure Antigravity Gemini integration"; Flags: runhidden waituntilterminated
Filename: "powershell.exe"; Parameters: "-NoProfile -ExecutionPolicy Bypass -File ""{app}\Install-VSCodeExtension.ps1"" -VsixPath ""{app}\vscode-extension\markplane-vscode-0.1.2.vsix"" -ShowSummary"; Description: "Install Markplane VS Code and Antigravity IDE integration"; Flags: runhidden waituntilterminated

[UninstallRun]
Filename: "powershell.exe"; Parameters: "-NoProfile -ExecutionPolicy Bypass -File ""{app}\Install-MarkplaneForCodex.ps1"" -Uninstall -InstallDir ""{app}"""; Flags: runhidden waituntilterminated; RunOnceId: "RemoveMarkplaneCodexIntegration"
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



