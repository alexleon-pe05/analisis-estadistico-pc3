# CLAUDE.md
This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Proyecto
Portal web estático educativo para visualizar el análisis estadístico del examen PC3 de Ingeniería Industrial (UNI). Compara soluciones en 4 herramientas: Excel, Minitab, Python y R.

## Ejecución

No hay sistema de build ni gestor de paquetes. Es HTML estático puro.

- **Abrir directamente:** doble clic en `index.html`
- **Con servidor local (recomendado para que funcione `fetch()` en `anexos.html`):**
  ```powershell
  # Python
  python -m http.server 8080
  # Node (si está instalado)
  npx serve .
  ```

## Arquitectura

Sitio multipágina estático. Flujo de navegación:

```
index.html → problema1.html → problema2.html → problema3.html → anexos.html
```

La barra de navegación superior está duplicada en cada archivo HTML (no hay componente compartido), aunque su **estilo** sí está centralizado en `css/style.css` (ver «Sistema de diseño visual»). Tailwind CSS se carga vía CDN con configuración de tema extendida (Material Design 3) embebida en un `<script id="tailwind-config">` dentro de **cada** archivo HTML — si se cambia la paleta de colores, hay que actualizarla en todos los archivos.

## Convenciones críticas

### Estructura de imágenes por problema

Cada problema sigue este esquema de nombres en `imagenes/problemaN/`:

```
enunciado.png       ← imagen del enunciado del problema (OBLIGATORIO)
formula_N.png        ← imagen con la formulación de hipótesis (OBLIGATORIO)
interpretacion_N.png ← imagen con interpretaciones y conclusiones (OBLIGATORIO)
excel_1.png – excel_4.png  ← capturas de Excel (máximo 4, pueden faltar algunas)
minitab_1.png – minitab_4.png
python_1.png – python_4.png
r_1.png – r_4.png
```

**Importante:**
- `formula_N.png` e `interpretacion_N.png` llevan el número del problema (ej. `formula_1.png`, `interpretacion_1.png`).
- El HTML tiene **slots de hasta 4 imágenes por herramienta**, pero **no es obligatorio** que existan todas. El lightbox en `js/main.js` oculta silenciosamente las que faltan.
- Solo `enunciado.png`, `formula_N.png` e `interpretacion_N.png` son obligatorios.

### Layout de cada página de problema

Cada `problemaN.html` tiene tres bloques basados en imágenes:

1. **Encabezado en 2 columnas** (`grid lg:grid-cols-12`): a la izquierda **Enunciado del Problema** (`col-span-5`, `enunciado.png`), a la derecha **Formulación de Hipótesis** (`col-span-7`, `formula_N.png`). En pantallas chicas se apilan.
2. **Grid de 4 herramientas** (Excel, Minitab, Python, R) con las capturas `_1` a `_4`.
3. **Callout "Interpretaciones y Conclusiones"** (recuadro azul `#eef4fb` con borde `#2d7fd4`): una sola imagen `interpretacion_N.png` que contiene los 4 apartados (interpretación ANOVA, interpretación Tukey, diferencias entre software y conclusión).

Antes la formulación de hipótesis y las interpretaciones eran placeholders de texto; ahora ambas se sirven como imagen para que el profesor pegue capturas ya formateadas. Todas las imágenes llevan la clase `img-lightbox` para ampliarse con clic.

### Estructura de códigos por problema

```
codigos/problemaN/
    analisis.py   ← ANOVA factorial con matplotlib/statsmodels/scipy
    analisis.R    ← Equivalente en R con ggplot2/dplyr/gridExtra
```

Los scripts **no se ejecutan desde esta carpeta**. Son copias traídas desde otro proyecto donde sí se corren. Están aquí únicamente para que el profesor los visualice o descargue desde `anexos.html`. La ruta hardcodeada en `analisis.R` línea 216 es intencional y corresponde al proyecto de ejecución original.

**Nota:** Los nombres de los archivos que los scripts generan al ejecutarse (ej. `P1_resultados.png`) **no importan** para el sitio web. Las imágenes que muestra el HTML (`python_1.png`, `r_1.png`, etc.) se copian/pegan manualmente desde el proyecto de ejecución original. El código solo está para consulta y descarga.

## Cómo agregar un problema nuevo (Problema 2 o 3)

1. Agregar 19 imágenes en `imagenes/problemaN/` con los nombres exactos del esquema anterior (16 capturas de herramientas + `enunciado.png` + `formula_N.png` + `interpretacion_N.png`)
2. Crear `codigos/problemaN/analisis.py` y `analisis.R`
3. El HTML del problema ya existe como plantilla — solo agregar las imágenes con los nombres correctos

## Sistema de diseño visual (efectos estilo Cult UI)

Los efectos visuales reutilizables están centralizados en `css/style.css` (no duplicar en el HTML). Están inspirados en componentes de [Cult UI](https://cult-ui.com) y recreados en CSS/JS puro para que funcionen en el sitio estático (sin React). Cada bloque lleva un comentario `/* ... */` que lo identifica.

### Barra de navegación (dock)
`nav.fixed` recibe cristal esmerilado (`backdrop-filter: blur`) y cada enlace se eleva al pasar el mouse. Se aplica **automáticamente vía CSS** a todas las páginas: la nav sigue duplicada en cada HTML, pero su estilo no. Usa `!important` para ganarle a las clases de Tailwind.

### Tarjetas de herramientas
Para que una caja de herramienta tenga barra de color + brillo al pasar el mouse, añadir al contenedor exterior:
```html
<div class="tool-card ..." data-tool="excel">   <!-- excel | minitab | python | r -->
```
- El **color** va en una barra superior (`.tool-card::before` + variable CSS `--accent`), **no** en `border-top-color` (Tailwind CDN lo pisa por especificidad de cascada).
- El brillo diagonal en hover es `.tool-card::after`; la elevación es `transform` en `:hover`.
- Colores de acento: excel `#16a34a`, minitab `#7c3aed`, python `#2563eb`, r `#0ea5e9`.
- ⚠️ Las 3 páginas de problema tienen estructuras de tarjeta **distintas** (`problema1` usa la caja de imágenes; `problema2` y `problema3` usan el contenedor con fondo). La clase se aplica al contenedor exterior de cada una; revisar el HTML antes de editar.

### Títulos con degradado
Cualquier encabezado `<h1>`–`<h4>` con la clase `text-[#1a2a4a]` recibe **automáticamente** el degradado azul animado (regla en `css/style.css`). No hay que añadir nada al HTML. La clase explícita `.gradient-title` produce el mismo efecto si se necesita en otro elemento.

### Portada (`index.html`)
Es autocontenida: su CSS va en un `<style>` propio (no usa el tema Tailwind de las demás páginas). Efectos: título con degradado animado, contadores animados (`.stat-num` con atributo `data-target`), botón con barrido de brillo, borde luminoso giratorio (`@property --beam-angle`) y orbes de luz flotantes.

### Reglas a tener en cuenta
- **Tailwind se inyecta en runtime** (Play CDN), por eso los estilos custom de `style.css` necesitan `!important` o mayor especificidad para ganar la cascada.
- Todo respeta `prefers-reduced-motion` (desactiva animaciones para quien lo prefiera).
- Tras editar `css/style.css`, forzar recarga del navegador con **Ctrl + Shift + R** (el navegador cachea el CSS).

## Dependencias implícitas

No hay `requirements.txt` ni `package.json`. Las dependencias son:

| Herramienta | Librerías necesarias |
|-------------|----------------------|
| Python 3    | `pandas`, `numpy`, `matplotlib`, `statsmodels`, `scipy` |
| R           | `ggplot2`, `dplyr`, `gridExtra` |
| Browser     | Tailwind CSS, Google Fonts, Material Symbols (todos via CDN) |

## Estado actual del proyecto

- **Problema 1:** completo (capturas + código Python/R)
- **Problema 2:** tiene plantilla HTML, algunas capturas parciales y código Python/R
- **Problema 3:** tiene plantilla HTML, algunas capturas parciales y código Python/R
