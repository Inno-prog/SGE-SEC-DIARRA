#define MyAppName "SGE SecDiarra"
#define MyAppVersion "1.0.0"
#define MyAppPublisher "Cabinet SecDiarra"
#define MyAppExeName "sge_secdiarra.exe"

[Setup]
AppId=A1B2C3D4-E5F6-7890-ABCD-EF1234567890
AppName={#MyAppName}
AppVersion={#MyAppVersion}
AppPublisher={#MyAppPublisher}
DefaultDirName={pf}\{#MyAppName}
DefaultGroupName={#MyAppName}
AllowNoIcons=yes
OutputDir=build/windows/installer
OutputBaseFilename=SGE_SecDiarra_Setup
SetupIconFile=
Compression=lzma
SolidCompression=yes
PrivilegesRequired=admin

[Files]
Source: "..\build\windows\x64\runner\Release\*"; DestDir: "{app}"; Flags: ignoreversion recursesubdirs createallsubdirs

[Icons]
Name: "{group}\{#MyAppName}"; Filename: "{app}\{#MyAppExeName}"

[Run]
Filename: "{app}\{#MyAppExeName}"; Description: "{cm:LaunchProgram,{#StringChange(MyAppName, '&', '&&')}}"; Flags: nowait postinstall skipifsilent
