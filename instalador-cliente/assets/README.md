# assets/

Coloca aquí el ícono de la empresa en formato `.ico` con el nombre exacto:

```
company.ico
```

Requisitos recomendados para el `.ico`:
- Multi-resolución: incluir al menos 16x16, 32x32, 48x48 y 256x256 dentro del
  mismo archivo `.ico` (herramientas como [ICOFX](https://icofx.ro/),
  [GIMP](https://www.gimp.org/) o conversores online como
  [convertico.com](https://convertico.com/) generan esto desde un PNG).
- Fondo transparente si el logo no es cuadrado.

Este ícono se usa para:
- El ícono del propio instalador (`SetupIconFile`).
- El acceso directo del Menú Inicio y Escritorio que se crea tras instalar.

> No cambia el ícono interno del ejecutable `rustdesk.exe` en sí (eso requiere
> recompilar RustDesk desde el código fuente), solo el ícono visible en los
> accesos directos creados por este instalador.
