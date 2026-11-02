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

## Bug conocido y corregido: "Falta el icono de acceso directo"

Versiones del `.iss` anteriores a esta corrección generaban accesos directos
rotos: el acceso directo apunta a `{app}\rustdesk.exe` (ej.
`C:\Program Files\PrimeTec RustDesk\rustdesk.exe`), pero el MSI oficial se
instalaba sin indicarle carpeta, así que `rustdesk.exe` terminaba en
`C:\Program Files\RustDesk\rustdesk.exe` (carpeta distinta). Resultado: al
hacer doble clic, Windows mostraba "Falta el icono de acceso directo".

Ya está corregido pasando `INSTALLFOLDER="{app}"` al `msiexec` para que el
MSI se instale en la misma carpeta que usan los accesos directos, y
desactivando los accesos directos propios del MSI (`CREATESTARTMENUSHORTCUTS`
/ `CREATEDESKTOPSHORTCUTS` en "N") para no duplicarlos.

**Para los equipos que ya instalaron la versión con el bug**, hay dos
opciones (no hace falta reinstalar todo si no quieres):
- Rápida: edita el acceso directo roto (clic derecho > Propiedades) y cambia
  el "Destino" a `C:\Program Files\RustDesk\rustdesk.exe`.
- Recomendada: vuelve a compilar el instalador con el `.iss` corregido y
  reinstala (el MSI detecta la instalación previa y la reubica/actualiza).

## Estado actual

Ya se compiló y validó una vez (en Linux, vía Docker + Wine con la imagen
`amake/innosetup`, usando el MSI oficial 1.5.0 y un ícono placeholder) para
confirmar que el `.iss` compila sin errores y genera un `.exe` válido
(`Instalador-PrimeTec-RustDesk.exe`, PE32 GUI de ~27 MB). Esa verificación
solo confirma que el script compila y empaqueta bien; **no reemplaza probar
el instalador en un Windows real**, porque el comportamiento en tiempo de
ejecución (instalación silenciosa del MSI, escritura de `RustDesk2.toml`,
reinicio del servicio `RustDesk`) solo puede validarse en Windows de verdad.
Antes de distribuirlo a usuarios finales, sigue el paso 5 de abajo (probar en
una VM o equipo de prueba) con el ícono real de la empresa.

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
     /DRD_APP_NAME="PrimeTec RustDesk" ^
     /DRD_COMPANY_NAME="PrimeTec" ^
     /DRD_VERSION="1.5.0" ^
     /DRD_HOST="rustdesk.primetec.cl" ^
     /DRD_KEY="4KDYvmOasvAG4dG1k+KYwBsuprgwP1DownC21Jw18Gs=" ^
     /DRD_API="https://rustdesk.primetec.cl" ^
     /DRD_PASSWORD="UnaClaveFija123!"
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
   - Debe quedar accesible **sin que nadie acepte la conexión** (ver
     siguiente sección).

## Acceso desatendido (servidores sin nadie frente a la pantalla)

El instalador configura automáticamente una **contraseña permanente** y pone
el modo de aprobación de RustDesk en `approve-mode = 'password'`, para que la
conexión entre con solo la contraseña, sin el popup de "Aceptar conexión" y
sin que haya una sesión de usuario abierta.

- Si compilas pasando `/DRD_PASSWORD="algo"`, esa es la contraseña fija que
  queda en todos los equipos instalados con ese build (útil si quieres que
  todo el equipo de soporte use la misma clave para todos los servidores).
- Si **no** pasas `/DRD_PASSWORD` (o compilas desde el IDE con Ctrl+F9), cada
  equipo genera su propia contraseña aleatoria distinta al instalar, y la
  deja guardada en texto plano en:
  ```
  C:\Program Files\PrimeTec RustDesk\PrimeTec-RustDesk-Password.txt
  ```
  Como la instalación es 100% silenciosa (pensada para correr en servidores
  sin nadie presente), no se muestra ningún aviso en pantalla: hay que ir a
  leer ese archivo después de instalar para obtener la contraseña de ese
  equipo en particular.
- El ID de cada equipo se puede ubicar en el panel web de `rustdesk-api`
  (`https://rustdesk.primetec.cl`) buscando por nombre de host, ya que no hay
  forma de verlo en pantalla en un servidor sin sesión interactiva.

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

## Subir los cambios al repo (GitHub)

Este repo local (`/home/rcid/rustdesk`) ya tiene un commit con todo lo de
`instalador-cliente/` y el remoto `origin` apuntando a
`https://github.com/PrimeTecCL/RustDesk.git`. Para subirlo (hazlo tú, con tu
propia sesión/autenticación de GitHub):

```bash
cd /home/rcid/rustdesk
git fetch origin        # por si el repo remoto ya tiene historia propia
git push -u origin master
```

Si `git fetch` trae commits que no están en este historial local y hay
conflicto, no fuerces el push: avisa para resolverlo con un
`git pull --rebase origin master` antes de subir.

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
