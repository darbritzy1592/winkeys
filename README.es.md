# WinKeys

[English](README.md) · **Español**

**Tus atajos de Windows, funcionando en el Mac.**

Acabas de pasarte al Mac. `Ctrl+C` no hace nada. `Inicio` te manda al principio
del documento en vez de al principio de la línea. Cada día intentas un atajo que
antes funcionaba, y cada día el Mac lo ignora.

WinKeys lo arregla con un interruptor y sin configurar nada.

<p align="center">
  <img src="docs/welcome-es.png" width="440" alt="Ventana de bienvenida de WinKeys">
</p>

## Qué hace

| Pulsas | WinKeys lo convierte en |
|---|---|
| `Ctrl+C` `Ctrl+V` `Ctrl+X` | Copiar, pegar, cortar |
| `Ctrl+Z` / `Ctrl+Y` | Deshacer / rehacer |
| `Ctrl+A` `Ctrl+S` `Ctrl+F` `Ctrl+P` `Ctrl+O` `Ctrl+N` | Lo que esperas |
| `Inicio` / `Fin` | Principio / final de la **línea** |
| `Ctrl+Inicio` / `Ctrl+Fin` | Principio / final del documento |

Y cada vez que traduce uno, te dice cómo se llama en Mac. La idea es que dejes
de necesitarla.

## No se mete donde no debe

`Ctrl+C` en una terminal significa *cancelar*, no *copiar*. Dentro de una máquina
virtual el sistema invitado ya habla Windows. Traducir ahí rompería cosas de las
que dependes, así que WinKeys nunca toca:

Terminal · iTerm2 · Warp · Alacritty · kitty · WezTerm · Hyper · Tabby ·
VS Code · Cursor · JetBrains · Sublime · Zed · Parallels · VMware Fusion ·
UTM · VirtualBox · Escritorio Remoto de Microsoft · Compartir Pantalla ·
TeamViewer · AnyDesk · Termius

Puedes añadir las tuyas.

## Privacidad

WinKeys lee las teclas que pulsas para poder traducirlas, y nada más.

- **No** guarda lo que escribes.
- **No** envía nada a ningún sitio.
- Se conecta a internet **solo** cuando pulsas "Buscar actualizaciones".
- **Nunca** instala una actualización por su cuenta: abre la página y decides tú.

El código está aquí. Una app que ve todo lo que tecleas debería ser una que
puedas leer, así que es [GPL-3.0](LICENSE) y siempre lo será.

## Requisitos

- **macOS 10.13 High Sierra o posterior** — incluidos Macs que no pueden ir más allá
- **Intel y Apple Silicon** — un único binario universal, sin descargas separadas
- El permiso de **Accesibilidad**, que es lo que permite leer el teclado. Nada más.

## Instalación

**[⬇ Descargar WinKeys 0.1.0](https://github.com/neural-beat/winkeys/releases/latest/download/WinKeys-0.1.0.zip)**

> **Descarga `WinKeys-0.1.0.zip`, no "Source code (zip)".**
> El archivo de código fuente contiene el código, no la aplicación: dentro no hay
> ninguna `.app` y no ocurrirá nada al abrirlo. El que buscas es el que se llama
> `WinKeys-<versión>.zip`.

1. Descomprímelo y arrastra `WinKeys.app` a tu carpeta de Aplicaciones.
2. **Clic derecho en la app → Abrir → Abrir.** WinKeys no está notarizada por
   Apple, así que un doble clic normal será rechazado la primera vez.
3. Concede el permiso de Accesibilidad cuando te lo pida.

Si macOS sigue negándose a abrirla:

```bash
xattr -dr com.apple.quarantine /Applications/WinKeys.app
```

### ¿Dónde está después de abrirla?

**En la barra de menús, no en el Dock.** WinKeys no tiene icono en el Dock ni
ventana principal: busca el icono de teclado arriba a la derecha de la pantalla.
Todo está en ese menú: el interruptor, el idioma y si se abre al iniciar sesión.

## Compilarla tú mismo

```bash
git clone https://github.com/neural-beat/winkeys.git
cd winkeys
./Tools/setup-signing.sh   # opcional, conserva los permisos entre compilaciones
./build.sh
```

`./build.sh` genera un `build/stage/WinKeys.app` universal. El script de firma
crea un certificado autofirmado en tu Mac; sin él, cada compilación tiene una
identidad distinta y macOS vuelve a pedirte el permiso de Accesibilidad cada vez.

## Idiomas

Inglés y español. Sigue el idioma del sistema la primera vez, y puedes cambiarlo
desde la pantalla de bienvenida o la barra de menús cuando quieras.

## Licencia

GPL-3.0-or-later. Creado por [neural-beat](https://github.com/neural-beat).
