# Instalador customizado de RustDesk para Windows (cliente remoto)

Este instalador es un **"wrapper"** sobre el instalador oficial de RustDesk:
no recompila la app (eso sería la opción "Pro" o "compilar desde fuente"),
pero genera un único `.exe` que:

1. Instala el MSI oficial de RustDesk en modo silencioso (sin pasos manuales).
2. Deja ya configurado el servidor propio de PrimeTec (`rendezvous`, `key`,
   `api-server`), sin que el usuario final tenga que tocar nada.
3. Usa un ícono y nombre de acceso directo con la marca de la empresa
   (ej. "PrimeTec RustDesk" en vez de "RustDesk").
4. Es **parametrizable**: la misma plantilla (`PrimeTecRustDesk.iss`) sirve
   para generar instaladores de otras empresas/servidores cambiando solo
   unos parámetros al compilar, sin editar el script.

> **Limitación conocida:** el nombre interno de la ventana/proceso seguirá
> diciendo "RustDesk" (eso solo se puede cambiar recompilando el cliente
> desde el código fuente de `rustdesk/rustdesk`, o contratando la versión Pro
> con el generador oficial de "Custom Client"). Lo que sí cambia con este
> wrapper: el nombre del instalador, el ícono y nombre del acceso directo, y
> la configuración de servidor ya viene incrustada.

## Requisitos (en tu PC Windows)

1. **Inno Setup 6** (gratuito): https://jrsoftware.org/isdl.php
   - Instala la versión normal (no hace falta la "QSP" ni plugins extra).
2. El **instalador MSI oficial de RustDesk** correspondiente a la versión que
   quieras empaquetar: https://github.com/rustdesk/rustdesk/releases
   - Ejemplo: `rustdesk-1.5.0-x86_64.msi`.
3. El **ícono de la empresa** en formato `.ico` (ver `assets/README.md`).

## Estructura de esta carpeta

```
instalador-cliente/
├── PrimeTecRustDesk.iss   <- script de Inno Setup (la plantilla parametrizable)
├── INSTRUCCIONES.md       <- este archivo
├── assets/
│   ├── README.md
│   └── company.ico        <- (lo agregas tú, no está versionado el logo real)
└── redist/
    ├── README.md
    └── rustdesk-1.5.0-x86_64.msi   <- (lo descargas tú, no está versionado)
```

## Pasos para compilar el instalador en Windows

1. Clona/descarga este repo en tu PC Windows y ubica la carpeta
   `instalador-cliente/`.
2. Descarga el MSI oficial de RustDesk (ver `redist/README.md`) y colócalo en
   `instalador-cliente/redist/rustdesk-1.5.0-x86_64.msi`.
3. Coloca tu ícono de empresa en `instalador-cliente/assets/company.ico` (ver
   `assets/README.md` para requisitos del formato).
4. Abre `PrimeTecRustDesk.iss` con el editor de Inno Setup (doble clic) y
   presiona **Build > Compile** (o `Ctrl+F9`).
   - Esto usa los valores por defecto ya cargados para PrimeTec (host, key,
     api-server) que están al inicio del `.iss`.
   - El `.exe` resultante queda en `instalador-cliente/output/`.

   **Alternativa por línea de comandos** (más cómoda para generar variantes
   para distintos clientes/servidores sin editar el `.iss`):

   ```bat
   "C:\Program Files (x86)\Inno Setup 6\ISCC.exe" PrimeTecRustDesk.iss ^
     /DAPP_NAME="PrimeTec RustDesk" ^
     /DCOMPANY_NAME="PrimeTec" ^
     /DRD_VERSION="1.5.0" ^
     /DRD_HOST="rustdesk.primetec.cl" ^
     /DRD_KEY="4KDYvmOasvAG4dG1k+KYwBsuprgwP1DownC21Jw18Gs=" ^
     /DRD_API="https://rustdesk.primetec.cl"
   ```

5. Prueba el instalador generado en una VM o equipo de prueba (con
   privilegios de administrador, hace falta porque instala un servicio de
   Windows):
   - Debe instalar RustDesk sin preguntar nada.
   - Al abrir RustDesk, el ID debe quedar registrado contra
     `rustdesk.primetec.cl` automáticamente (compáralo con lo que hace hoy
     `manual/cliente/Instalar-RustDesk-PrimeTec.ps1`, que hace lo mismo pero
     como script en vez de instalador).
   - El acceso directo del Menú Inicio/Escritorio debe mostrar el ícono y
     nombre de la empresa.

## Actualizar a una nueva versión de RustDesk

Cuando salga una nueva versión del cliente oficial:
1. Descarga el nuevo MSI y reemplázalo en `redist/`.
2. Vuelve a compilar pasando `/DRD_VERSION="X.Y.Z"` (o editando el valor por
   defecto en el `.iss`).

No hace falta tocar nada más: la key y el servidor no cambian entre
versiones de RustDesk.

## Generar instaladores para otra empresa/servidor (reutilizar la plantilla)

Como el `.iss` es parametrizable vía `/D...`, para otro cliente solo se
necesita:
- Su propio ícono `.ico`.
- Su `rendezvous_server` / `key` / `api-server` (se generan al configurar su
  propio `rustdesk-server`, igual que está documentado para PrimeTec en
  `docker-compose.yml` y `manual/`).
- Compilar con los `/D` correspondientes a ese cliente.

## Alternativas descartadas (para referencia futura)

- **RustDesk Pro / Custom Client oficial**: requiere licencia paga de
  `rustdesk-server-pro` (desde ~US$39.99/mes). A cambio da un generador web
  con firma de código y cambia también el nombre interno de la app. Se
  descartó por ahora por el costo.
- **Compilar RustDesk desde el código fuente**: gratis, y es la única forma
  de cambiar el nombre interno/branding completo de la app, pero exige
  mantener un entorno de compilación Windows (Rust + Flutter + Visual Studio
  Build Tools + vcpkg) y repetir el proceso en cada actualización de versión.
  Queda como opción a futuro si se necesita branding más profundo.
