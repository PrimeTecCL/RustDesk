# Instalar-RustDesk-PrimeTec.ps1
#
# Instala (si hace falta) y configura RustDesk para usar el servidor propio
# de PrimeTec (rustdesk.primetec.cl). Usa el paquete MSI oficial (instalacion
# silenciosa recomendada por la documentacion de RustDesk, mas confiable que
# el .exe --silent-install). La Key del servidor queda guardada unicamente en
# el archivo de configuracion local del equipo (RustDesk2.toml), igual que si
# se ingresara a mano en Configuracion -> Red -> Aplicar.
#
# Uso: ejecutar como Administrador.
#   powershell -ExecutionPolicy Bypass -File Instalar-RustDesk-PrimeTec.ps1

$ErrorActionPreference = 'Stop'

# ----------------- Configuracion del servidor PrimeTec -----------------
$RustDeskHost = "rustdesk.primetec.cl"
$RustDeskKey  = "4KDYvmOasvAG4dG1k+KYwBsuprgwP1DownC21Jw18Gs="
$RustDeskApi  = "https://rustdesk.primetec.cl"
$InstallerUrl = "https://github.com/rustdesk/rustdesk/releases/download/1.5.0/rustdesk-1.5.0-x86_64.msi"
# -------------------------------------------------------------------------

# Relanzar como administrador si hace falta
$isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
if (-not $isAdmin) {
    Start-Process powershell -Verb RunAs -ArgumentList "-ExecutionPolicy Bypass -File `"$PSCommandPath`""
    exit
}

$exePath = "C:\Program Files\RustDesk\rustdesk.exe"
$alreadyInstalled = (Test-Path $exePath) -or (Get-Service -Name "RustDesk" -ErrorAction SilentlyContinue)

if ($alreadyInstalled) {
    Write-Host "RustDesk ya esta instalado en este equipo. Se omite la instalacion y solo se aplica la configuracion del servidor." -ForegroundColor Yellow
} else {
    Write-Host "Descargando instalador oficial de RustDesk (MSI)..."
    $msiPath = Join-Path $env:TEMP "rustdesk-setup.msi"
    $logPath = Join-Path $env:TEMP "rustdesk-install.log"
    Invoke-WebRequest -Uri $InstallerUrl -OutFile $msiPath -UseBasicParsing

    Write-Host "Instalando RustDesk en silencio..."
    $proc = Start-Process "msiexec.exe" -ArgumentList "/i `"$msiPath`" /qn /l*v `"$logPath`"" -Wait -PassThru

    if ($proc.ExitCode -ne 0) {
        Write-Warning "msiexec devolvio codigo $($proc.ExitCode). Revisa el log: $logPath"
        Write-Host "Ultimas lineas del log:"
        Get-Content $logPath -Tail 40 -ErrorAction SilentlyContinue
        exit 1
    }
    Write-Host "Instalacion completada."
}

Write-Host "Esperando que el servicio de RustDesk quede creado..."
$svc = $null
for ($i = 0; $i -lt 30; $i++) {
    $svc = Get-Service -Name "RustDesk" -ErrorAction SilentlyContinue
    if ($svc) { break }
    Start-Sleep -Seconds 1
}
if (-not $svc) {
    Write-Warning "No se detecto el servicio 'RustDesk' tras la instalacion. Revisa manualmente (Servicios de Windows)."
}

$configDir = "C:\Windows\ServiceProfiles\LocalService\AppData\Roaming\RustDesk\config"
New-Item -ItemType Directory -Force -Path $configDir | Out-Null

Write-Host "Deteniendo servicio RustDesk para aplicar configuracion..."
if ($svc) { Stop-Service -Name "RustDesk" -Force -ErrorAction SilentlyContinue }
Start-Sleep -Seconds 2

$tomlContent = @"
rendezvous_server = '$RustDeskHost'
nat_type = 1
serial = 0

[options]
key = '$RustDeskKey'
relay-server = '$RustDeskHost'
api-server = '$RustDeskApi'
custom-rendezvous-server = '$RustDeskHost'
"@

$tomlPath = Join-Path $configDir "RustDesk2.toml"
Set-Content -Path $tomlPath -Value $tomlContent -Encoding ASCII

Write-Host "Reiniciando servicio RustDesk..."
if ($svc) { Start-Service -Name "RustDesk" -ErrorAction SilentlyContinue }

Write-Host ""
Write-Host "Listo. RustDesk quedo configurado para usar $RustDeskHost." -ForegroundColor Green
Write-Host "Abre RustDesk para ver el ID asignado por el servidor y compartirlo con soporte TI."
