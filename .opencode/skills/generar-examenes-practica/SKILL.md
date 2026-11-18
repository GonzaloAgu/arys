---
name: generar-examenes-practica
description: Genera exámenes de práctica en examen.md con consignas compactas, sin espacios de respuesta, PDF vía pandoc y multiple choice con respuesta correcta aleatorizada. Úsala cuando el usuario pida "generar un examen", "examen de práctica", "examen.md" o un examen en PDF.
---

# Generar exámenes de práctica

## Cuándo usarla

Usar esta skill cuando el pedido sea generar o rehacer un **examen de práctica**
(o un examen en PDF) a partir del material de la cátedra. No usarla para TPs,
informes ni para resolver ejercicios.

## 1. Fuentes y alcance

- Leer primero el material relevante de `bibliografia/unidad-XX-*.md` y, si
  existe, `apuntes/`.
- Respetar las unidades, duración y temas que pida el usuario. Si no los
  precisa, preguntar antes de escribir.
- Redactar en español y mantener el registro del material de la cátedra.
- No modificar `consigna.md` ni `solucion.md` de los TPs.

## 2. Archivo de salida

- Escribir el examen en `examen.md` en la raíz del repo, salvo que el usuario
  indique otra ruta.
- **No pisar un examen existente si el usuario dice que ya empezó a resolverlo.**
  En ese caso crear `examen-2.md` (o el nombre que indique) y avisar.
- El PDF se genera al lado del Markdown, con el mismo nombre base.

## 3. Formato: práctico, compacto y sin espacios de respuesta

Un examen de práctica **no** debe parecer un examen formal. Evitar todo el
boilerplate:

- No incluir campos de alumno, legajo, fecha, comisión, docente ni universidad.
- No incluir carátula, tabla de puntajes, condiciones de aprobación ni
  instrucciones generales.
- No incluir bibliografía ni referencias al final (salvo que el usuario lo pida
  expresamente o el examen sea formal).
- Encabezado mínimo: título, materia, puntaje total y duración en una o dos
  líneas. Aclarar una sola vez: “Todas las respuestas se escriben en hojas
  separadas.”

**No dejar espacios para responder sobre la hoja.** Esto incluye:

- recuadros o cajas de respuesta;
- líneas o renglones en blanco;
- tablas con celdas vacías para completar;
- grillas de respuestas;
- leyendas del tipo “Tema elegido: ______” o “Respuesta: ______”.

Las preguntas que pidan completar o comparar una tabla deben pedir que el
alumno la confeccione en su hoja, no incluir la tabla vacía.

### Estilo compacto

- Fuente base de **9 pt** y `line-height: 1.3`.
- Márgenes internos chicos, párrafos y listas con poco espaciado.
- **Sin saltos de página forzados**: no usar `.newpage`, `page-break-before`,
  `page-break-after` ni divs de salto.
- Aprovechar el papel: evitar títulos gigantes y bloques de relleno. Para un
  examen de 2 horas, apuntar a unas 3–5 páginas.
- Usar el CSS compacto de referencia al final de esta skill.

## 4. Estructura sugerida

Adaptar según lo pedido. Una estructura típica:

1. **Verdadero o falso** — 5–6 afirmaciones con justificación.
2. **Múltiple choice** — 8–10 preguntas, una sola opción correcta.
3. **Desarrollo conceptual** — 4 temas para elegir 3, o 3 preguntas fijas.
4. **Ejercicio práctico** — por ejemplo, nftables si el tema es firewall.
5. **Tema secundario** — por ejemplo, autenticación si entra la Unidad 7.

Cada sección debe indicar su puntaje. Las respuestas no se incluyen en el
examen; si el usuario las pide, crear un archivo aparte (`respuestas.md`), no
mezclarlas con las consignas.

### Ejercicio práctico de nftables

Cuando el examen incluya nftables, usar un escenario realista y accionable:

- Tabla de zonas con interfaces, direcciones y equipos relevantes.
- Requisitos explícitos: SSH restringido, DNS, loopback, stateful,
  `ct state invalid drop`, DMZ, DNAT/SNAT, logging.
- Dividir en subtareas con puntaje (crear tabla y cadenas; reglas de input;
  forward; NAT; logging; verificar y persistir).
- Pedir comandos completos y explicación de cada regla.
- No incluir la solución ni pistas de sintaxis en el enunciado.

## 5. Multiple choice: respuesta correcta aleatorizada de verdad

**Nunca** dejar que todas o casi todas las correctas caigan en la misma letra
(por ejemplo, todo B). Antes de redactar las preguntas:

1. Definir cuántas preguntas habrá (`N`).
2. Generar una secuencia balanceada de letras correctas con
   `scripts/mc_answer_sequence.py`:

   ```sh
   python .opencode/skills/generar-examenes-practica/scripts/mc_answer_sequence.py 10
   ```

   La salida es una secuencia como `C A D B A C B D A C`.

3. Redactar cada pregunta colocando la opción correcta en la letra que indica
   la secuencia.
4. Conservar la secuencia en el razonamiento interno hasta terminar.
5. Verificar la secuencia usada:

   ```sh
   python .opencode/skills/generar-examenes-practica/scripts/mc_answer_sequence.py check C A D B A C B D A C
   ```

   Debe informar `VÁLIDA`: letras equilibradas (diferencia máxima 1 entre
   conteos), sin tres letras iguales consecutivas y solo A/B/C/D.

Si se agrega o elimina una pregunta, regenerar la secuencia y reasignar todas
las correctas. No “arreglar” la distribución moviendo solo una opción.

## 6. Generar el PDF con pandoc

En este repo no hay motor LaTeX instalado. El flujo probado es pandoc → HTML
estilizado → Chrome/Edge headless:

```sh
pandoc examen.md -f markdown+raw_attribute -t html5 --standalone \
  --embed-resources --css=tools/tp_style.css \
  --metadata pagetitle="Examen de práctica" --metadata lang=es-AR \
  -o examen.html

# Ajustar la ruta al Chrome/Edge instalado
& "C:\Program Files\Google\Chrome\Application\chrome.exe" \
  --headless=new --disable-gpu --no-margins --no-pdf-header-footer \
  --user-data-dir="$env:TEMP\chrome_examen" \
  --print-to-pdf="examen.pdf" "file:///$((Resolve-Path examen.html).Path.Replace('\','/'))"

Remove-Item examen.html
```

Verificar que el PDF exista y tenga tamaño mayor que cero. Si hay un motor
PDF de pandoc disponible (`typst`, `weasyprint`, LaTeX), se puede usar
`pandoc examen.md -o examen.pdf`, pero el CSS y los fenced divs deben probarse
antes.

## 7. CSS compacto de referencia

Incluir este bloque al inicio de `examen.md` (pandoc lo conserva en el HTML):

```html
<style>
body { font-size: 9pt; line-height: 1.3; }
h1 { font-size: 15pt; margin: 0 0 4px; }
h2 { font-size: 11.5pt; margin: 10px 0 4px; }
h3 { font-size: 10pt; margin: 8px 0 3px; }
p { margin: 0 0 4px; }
ul, ol { margin: 2px 0 6px; }
li { margin: 1px 0; }
table { font-size: 8.5pt; margin: 4px 0 8px; }
th, td { padding: 3px 5px; }
pre { font-size: 7.5pt; padding: 6px 8px; margin: 4px 0 8px; }
code { font-size: 8pt; }
</style>
```

No agregar reglas de salto de página.

## 8. Checklist final

- [ ] El examen está en `examen.md` (o en el archivo indicado) y no se pisó un
      examen que el usuario ya estaba resolviendo.
- [ ] No hay carátula, datos de alumno, instrucciones generales ni bibliografía.
- [ ] No hay cajas, líneas, grillas ni tablas vacías para responder.
- [ ] No hay saltos de página forzados; el PDF es compacto (3–5 páginas para
      2 horas).
- [ ] La fuente base es de 9 pt y el espaciado es ajustado.
- [ ] Las preguntas de multiple choice usan una secuencia de correctas
      balanceada y verificada; ninguna letra concentra casi todas.
- [ ] El ejercicio práctico tiene escenario, requisitos y subtareas con puntaje,
      sin solución.
- [ ] El PDF se generó y se eliminó el HTML intermedio.
