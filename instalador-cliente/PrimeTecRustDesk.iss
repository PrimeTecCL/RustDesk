; =============================================================================
;  PrimeTecRustDesk.iss
;  Instalador "wrapper" de RustDesk, parametrizable por empresa/servidor.
;
;  Toma el instalador oficial MSI de RustDesk (sin recompilar nada) y lo
;  empaqueta junto con:
;    - La configuracion del servidor propio (rendezvous/key/api) ya incrustada
;    - Un icono y nombre de acceso directo personalizados (branding)
;    - Instalacion 100% silenciosa en un solo doble clic
;
;  Requiere: Inno Setup 6.x (https://jrsoftware.org/isinfo.php) en Windows.
;
;  COMPILACION PARAMETRIZADA (para reutilizar la plantilla con otros clientes
;  o servidores sin tocar este archivo), usando el compilador de linea de
;  comandos ISCC.exe:
;
;    ISCC.exe PrimeTecRustDesk.iss ^
;      /DAPP_NAME="PrimeTec RustDesk" ^
;      /DCOMPANY_NAME="PrimeTec" ^
;      /DRD_VERSION="1.5.0" ^
;      /DRD_HOST="rustdesk.primetec.cl" ^
;      /DRD_KEY="4KDYvmOasvAG4dG1k+KYwBsuprgwP1DownC21Jw18Gs=" ^
;      /DRD_API="https://rustdesk.primetec.cl"
;
;  Si compilas directo desde el IDE de Inno Setup (Ctrl+F9) se usan los
;  valores por defecto definidos mas abajo (los de PrimeTec).
; =============================================================================

#ifndef APP_NAME
  #define APP_NAME "PrimeTec RustDesk"
#endif
#ifndef COMPANY_NAME
  #define COMPANY_NAME "PrimeTec"
#endif
#ifndef RD_VERSION
  #define RD_VERSION "1.5.0"
#endif
#ifndef RD_HOST
  #define RD_HOST "rustdesk.primetec.cl"
#endif
#ifndef RD_KEY
  #define RD_KEY "4KDYvmOasvAG4dG1k+KYwBsuprgwP1DownC21Jw18Gs="
#endif
#ifndef RD_API
  #define RD_API "https://rustdesk.primetec.cl"
#endif

#define RD_MSI_NAME "rustdesk-" + RD_VERSION + "-x86_64.msi"

[Setup]
AppId={{B6E0B9F0-6B1A-4B1E-9C2E-PRIMETEC-RUSTDESK}}
AppName={#APP_NAME}
AppVersion={#RD_VERSION}
AppPublisher={#COMPANY_NAME}
DefaultDirName={autopf}\{#APP_NAME}
DefaultGroupName={#APP_NAME}
DisableProgramGroupPage=yes
OutputDir=output
OutputBaseFilename=Instalador-{#COMPANY_NAME}-RustDesk
SetupIconFile=assets\company.ico
UninstallDisplayIcon={app}\rustdesk.exe
Compression=lzma2
SolidCompression=yes
PrivilegesRequired=admin
ArchitecturesInstallIn64BitMode=x64
WizardStyle=modern

; Instalacion totalmente silenciosa: no muestra wizard ni pide nada al usuario.
; Quita estas 3 lineas si prefieres mostrar el wizard de Inno Setup.
DisableWelcomePage=yes
DisableReadyPage=yes

[Languages]
Name: "spanish"; MessagesFile: "compiler:Languages\Spanish.isl"

[Files]
; El MSI oficial de RustDesk debe estar en la carpeta redist\ antes de compilar
; (ver instrucciones.md, paso "Descargar el instalador oficial").
Source: "redist\{#RD_MSI_NAME}"; DestDir: "{tmp}"; Flags: deleteafterinstall
Source: "assets\company.ico"; DestDir: "{app}"; Flags: ignoreversion

[Icons]
Name: "{group}\{#APP_NAME}"; Filename: "{app}\rustdesk.exe"; IconFilename: "{app}\company.ico"
Name: "{autodesktop}\{#APP_NAME}"; Filename: "{app}\rustdesk.exe"; IconFilename: "{app}\company.ico"

[Run]
; 1) Instala el MSI oficial de RustDesk en modo silencioso
Filename: "msiexec.exe"; Parameters: "/i ""{tmp}\{#RD_MSI_NAME}"" /qn /norestart"; StatusMsg: "Instalando RustDesk..."; Flags: waituntilterminated

[Code]
procedure WriteServerConfig;
var
  ConfigDir, TomlPath, Content: String;
begin
  ConfigDir := ExpandConstant('{win}\ServiceProfiles\LocalService\AppData\Roaming\RustDesk\config');
  ForceDirectories(ConfigDir);
  TomlPath := ConfigDir + '\RustDesk2.toml';

  Content :=
    'rendezvous_server = ''' + '{#RD_HOST}' + '''' + #13#10 +
    'nat_type = 1' + #13#10 +
    'serial = 0' + #13#10 +
    #13#10 +
    '[options]' + #13#10 +
    'key = ''' + '{#RD_KEY}' + '''' + #13#10 +
    'relay-server = ''' + '{#RD_HOST}' + '''' + #13#10 +
    'api-server = ''' + '{#RD_API}' + '''' + #13#10 +
    'custom-rendezvous-server = ''' + '{#RD_HOST}' + '''' + #13#10;

  SaveStringToFile(TomlPath, Content, False);
end;

procedure RestartRustDeskService;
begin
  Exec(ExpandConstant('{sys}\sc.exe'), 'stop RustDesk', '', SW_HIDE, ewWaitUntilTerminated, ResultCode);
  Sleep(2000);
  Exec(ExpandConstant('{sys}\sc.exe'), 'start RustDesk', '', SW_HIDE, ewWaitUntilTerminated, ResultCode);
end;

procedure CurStepChanged(CurStep: TSetupStep);
begin
  if CurStep = ssPostInstall then
  begin
    WriteServerConfig;
    RestartRustDeskService;
  end;
end;
