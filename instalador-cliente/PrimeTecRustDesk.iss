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
;      /DRD_APP_NAME="PrimeTec RustDesk" ^
;      /DRD_COMPANY_NAME="PrimeTec" ^
;      /DRD_VERSION="1.5.0" ^
;      /DRD_HOST="rustdesk.primetec.cl" ^
;      /DRD_KEY="4KDYvmOasvAG4dG1k+KYwBsuprgwP1DownC21Jw18Gs=" ^
;      /DRD_API="https://rustdesk.primetec.cl"
;
;  Si compilas directo desde el IDE de Inno Setup (Ctrl+F9) se usan los
;  valores por defecto definidos mas abajo (los de PrimeTec).
; =============================================================================

#ifndef RD_APP_NAME
  #define RD_APP_NAME "PrimeTec RustDesk"
#endif
#ifndef RD_COMPANY_NAME
  #define RD_COMPANY_NAME "PrimeTec"
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
AppName={#RD_APP_NAME}
AppVersion={#RD_VERSION}
AppPublisher={#RD_COMPANY_NAME}
DefaultDirName={autopf}\{#RD_APP_NAME}
DefaultGroupName={#RD_APP_NAME}
DisableProgramGroupPage=yes
OutputDir=output
OutputBaseFilename=Instalador-{#RD_COMPANY_NAME}-RustDesk
SetupIconFile=assets\company.ico
UninstallDisplayIcon={app}\rustdesk.exe
Compression=lzma2
SolidCompression=yes
PrivilegesRequired=admin
ArchitecturesInstallIn64BitMode=x64compatible
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
Name: "{group}\{#RD_APP_NAME}"; Filename: "{app}\rustdesk.exe"; IconFilename: "{app}\company.ico"
Name: "{autodesktop}\{#RD_APP_NAME}"; Filename: "{app}\rustdesk.exe"; IconFilename: "{app}\company.ico"

[Run]
; 1) Instala el MSI oficial de RustDesk en modo silencioso
Filename: "msiexec.exe"; Parameters: "/i ""{tmp}\{#RD_MSI_NAME}"" /qn /norestart"; StatusMsg: "Instalando RustDesk..."; Flags: waituntilterminated

[UninstallRun]
; Al desinstalar "PrimeTec RustDesk" (desde Configuracion/Panel de Control),
; tambien se desinstala el RustDesk real instalado por el MSI, para que quede
; una sola entrada de desinstalacion y no sea necesario hacerlo dos veces.
Filename: "msiexec.exe"; Parameters: "/x {code:GetRustDeskProductCode} /qn /norestart"; Flags: runhidden waituntilterminated; RunOnceId: "UninstallRustDeskMsi"

[Code]
// Busca el codigo de producto (GUID) del "RustDesk" real instalado por el MSI,
// buscando en el registro de Windows por su DisplayName. Se usa tanto para
// detectar si ya esta instalado como para desinstalarlo via msiexec /x.
function FindRustDeskProductCode(var ProductCode: String): Boolean;
var
  Names: TArrayOfString;
  i: Integer;
  DisplayName, BaseKey: String;
begin
  Result := False;
  BaseKey := 'SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall';
  if RegGetSubkeyNames(HKLM, BaseKey, Names) then
  begin
    for i := 0 to GetArrayLength(Names) - 1 do
    begin
      if RegQueryStringValue(HKLM, BaseKey + '\' + Names[i], 'DisplayName', DisplayName) then
      begin
        if DisplayName = 'RustDesk' then
        begin
          ProductCode := Names[i];
          Result := True;
          Exit;
        end;
      end;
    end;
  end;
  BaseKey := 'SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall';
  if RegGetSubkeyNames(HKLM, BaseKey, Names) then
  begin
    for i := 0 to GetArrayLength(Names) - 1 do
    begin
      if RegQueryStringValue(HKLM, BaseKey + '\' + Names[i], 'DisplayName', DisplayName) then
      begin
        if DisplayName = 'RustDesk' then
        begin
          ProductCode := Names[i];
          Result := True;
          Exit;
        end;
      end;
    end;
  end;
end;

// Usado por el [UninstallRun] de arriba via {code:...}
function GetRustDeskProductCode(Param: String): String;
var
  Code: String;
begin
  if FindRustDeskProductCode(Code) then
    Result := Code
  else
    Result := '{00000000-0000-0000-0000-000000000000}';
end;

function ServiceExists(ServiceName: String): Boolean;
begin
  Result := RegKeyExists(HKLM, 'SYSTEM\CurrentControlSet\Services\' + ServiceName);
end;

procedure UninstallRustDeskReal;
var
  ProductCode: String;
  ResultCode: Integer;
begin
  if FindRustDeskProductCode(ProductCode) then
    Exec('msiexec.exe', '/x ' + ProductCode + ' /qn /norestart', '', SW_HIDE, ewWaitUntilTerminated, ResultCode);
end;

// Si RustDesk ya esta instalado en el equipo, en vez de reinstalarlo encima
// sin avisar, se pregunta una sola vez que hacer, con un cuadro de dialogo
// moderno (task dialog) con botones propios en vez del MessageBox generico.
function InitializeSetup(): Boolean;
var
  MsgResult: Integer;
begin
  Result := True;
  if ServiceExists('RustDesk') then
  begin
    MsgResult := TaskDialogMsgBox(
      '{#RD_APP_NAME} ya está instalado',
      'Se detectó una instalación existente de RustDesk en este equipo.' + #13#10 +
      '¿Qué deseas hacer?',
      mbInformation, MB_YESNOCANCEL, [
       'Reinstalar' + #13#10 + 'Vuelve a instalar y actualiza la configuración del servidor.',
       'Desinstalar' + #13#10 + 'Quita RustDesk por completo de este equipo.',
       'Cancelar' + #13#10 + 'Salir sin hacer cambios.'],
      IDYES);
    case MsgResult of
      IDNO:
        begin
          UninstallRustDeskReal;
          TaskDialogMsgBox('Desinstalación completa', 'RustDesk fue desinstalado de este equipo.',
            mbInformation, MB_OK, [], 0);
          Result := False;
        end;
      IDCANCEL:
        Result := False;
    end;
  end;
end;

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
    'serial = 0' + #13#10 + #13#10 +
    '[options]' + #13#10 +
    'key = ''' + '{#RD_KEY}' + '''' + #13#10 +
    'relay-server = ''' + '{#RD_HOST}' + '''' + #13#10 +
    'api-server = ''' + '{#RD_API}' + '''' + #13#10 +
    'custom-rendezvous-server = ''' + '{#RD_HOST}' + '''' + #13#10;

  SaveStringToFile(TomlPath, Content, False);
end;

procedure RestartRustDeskService;
var
  ResultCode: Integer;
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
