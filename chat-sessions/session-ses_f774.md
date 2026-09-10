# Esqueleto para solucion.md de TP2

**Session ID:** ses_f77428dcaffeWvyfrJVVGBXcc3
**Created:** 9/9/2026, 21:35:12
**Updated:** 10/9/2026, 18:10:57

---

## User

Preparame el solucion.md del TP2, con un esqueleto para luego rellenar con las soluciones.

---

## Assistant (Build · MiMo V2.5 Free · 13.2s)

_Thinking:_

The user is asking me to prepare a solution.md file for TP2 (Trabajo Práctico 2), with a skeleton to fill in later with solutions. They're speaking in Spanish.

Let me first check what files exist in the workspace to understand the project structure and find TP2-related files.

Voy a explorar la estructura del proyecto para entender el contexto del TP2.

**Tool: read**

**Input:**
```json
{
  "filePath": "C:\\Users\\gonza\\arys"
}
```

**Output:**
```
<path>C:\Users\gonza\arys</path>
<type>directory</type>
<entries>
.atl/
.git/
.gitattributes
.githooks/
.gitignore
apuntes/
bibliografia/
chat-sessions/
integrity/
opencode.json
openspec/
README.md
tools/
tps/

(14 entries)
</entries>
```

**Tool: glob**

**Input:**
```json
{
  "pattern": "**/*TP*"
}
```

**Output:**
```
C:\Users\gonza\arys\tps\1\ARyS_TP1_GonzaloAgu.pdf
```

**Tool: glob**

**Input:**
```json
{
  "pattern": "**/*tp*"
}
```

**Output:**
```
C:\Users\gonza\arys\tps\build_tp.py
```

---

## Assistant (Build · MiMo V2.5 Free · 4.8s)

_Thinking:_

Let me look at the tps directory to understand the structure better, and also check if there's already a TP2 folder.

**Tool: read**

**Input:**
```json
{
  "filePath": "C:\\Users\\gonza\\arys\\tps"
}
```

**Output:**
```
<path>C:\Users\gonza\arys\tps</path>
<type>directory</type>
<entries>
1/
2/
build_tp.py

(3 entries)
</entries>
```

**Tool: glob**

**Input:**
```json
{
  "pattern": "tps/**/*"
}
```

**Output:**
```
C:\Users\gonza\arys\tps\build_tp.py
C:\Users\gonza\arys\tps\2\consigna.md
C:\Users\gonza\arys\tps\1\consigna.md
C:\Users\gonza\arys\tps\1\ARyS_TP1_GonzaloAgu.pdf
C:\Users\gonza\arys\tps\1\trabajo_practico.docx
C:\Users\gonza\arys\tps\1\solucion.md
C:\Users\gonza\arys\tps\1\A\Captura-B.3.png
C:\Users\gonza\arys\tps\1\A\Captura-B.2.png
C:\Users\gonza\arys\tps\1\A\Captura-B.1.png
C:\Users\gonza\arys\tps\1\A\Captura B.4.png
```

---

## Assistant (Build · MiMo V2.5 Free · 4.8s)

_Thinking:_

There's already a TP1 with a solucion.md. Let me read both the TP1 solucion.md to understand the format/structure used, and the TP2 consigna.md to understand what needs to be solved.

**Tool: read**

**Input:**
```json
{
  "filePath": "C:\\Users\\gonza\\arys\\tps\\1\\solucion.md"
}
```

**Output:**
```
<path>C:\Users\gonza\arys\tps\1\solucion.md</path>
<type>file</type>
<content>
1: # Trabajo Práctico 1 — Conceptos de Seguridad
2: 
3: ## Parte A — El inventario y la tríada
4: 
5: Elijo como sistema, la PC de mi trabajo, en un organismo público.
6: 
7: | Activo | Pilar CIA crítico | Justificación |
8: |--------|-------------------|---------------|
9: | Administración del directorio compartido | Integridad | Si se alteran los archivos puede ser grave para las operaciones del organismo. |
10: | Administración de licencias de Microsoft | Confidencialidad | De filtrarse, se podría hacer un uso ilegítimo de nuestras licencias Office. |
11: | Gestor de backups del directorio compartido (Duplicati) | Integridad | La alteración del conjunto de backups puede dejar el organismo expuesto a la pérdida de datos. |
12: | Sitio web y su subsistema de reclamos | Confidencialidad y Disponibilidad | Su base de datos contiene datos personales de los reclamos. Si la página se cae, se pierde el servicio a los usuarios. |
13: | Mi cuenta de Teams | Confidencialidad | No es importante que esté disponible ni íntegro, pero es fundamental que nadie acceda a ella, o existe el peligro de ataques mediante suplantación de identidad. |
14: 
15: ### Mini análisis de riesgo — Activo principal
16: 
17: El activo más importante probablemente sea el de administración de directorios compartidos. La principal amenaza que veo es que algún tercero ingrese a mi máquina. Puede aprovecharse de la vulnerabilidad de que nuestras contraseñas son similares.
18: 
19: | Concepto | Valor |
20: |----------|-------|
21: | Amenaza | Acceso no autorizado de un tercero a la máquina |
22: | Vulnerabilidad | Contraseñas similares entre usuarios |
23: | Probabilidad | Bajo |
24: | Impacto | Alto |
25: 
26: > **Fuente:** Amenaza = "circunstancia o agente que pueda causar daño" (apuntes §4). Vulnerabilidad = "debilidad que la amenaza puede aprovechar" (apuntes §4). Riesgo = probabilidad × impacto (apuntes §4).
27: 
28: ---
29: 
30: ## Parte B — La tríada en acción
31: 
32: ### B.1 Integridad — funciones de hash
33: 
34: Se creó un archivo `orden.txt` con el contenido original y se calculó su hash SHA-256. Luego se alteró un solo carácter (1000 → 9000) y se volvió a calcular.
35: 
36: **Código ejecutado:**
37: 
38: ```bash
39: echo "Transferir 1000 a la cuenta 55" > orden.txt
40: Get-FileHash -Algorithm SHA256 orden.txt
41: 
42: echo "Transferir 9000 a la cuenta 55" > orden.txt
43: Get-FileHash -Algorithm SHA256 orden.txt
44: ```
45: 
46: **Comparación de hashes:**
47: 
48: | Versión | Contenido | SHA-256 |
49: |---------|-----------|---------|
50: | Original | Transferir 1000 a la cuenta 55 | `6068A4CC2E99372A1C21D015AC93CEC8D9993C22465CC7B68E3CD5D0C821B7E6` |
51: | Alterado | Transferir 9000 a la cuenta 55 | `95180D1A89125162D1B438C5725E49EB9906D28F7F677FD37D4970575C05E805` |
52: 
53: **Respuesta:**
54: 
55: Al cambiar un solo dígito (1000 → 9000), el hash SHA-256 cambió completamente. La integridad se protege con funciones de hash porque permiten detectar si la información fue alterada: si alguien modifica el archivo, el hash calculado no coincidirá con el original. Sin embargo, el hash no sirve para deshacer la alteración porque es una función unidireccional — solo permite saber *si* el archivo fue modificado, pero no *qué* cambió ni cómo restaurarlo.
56: 
57: > **Fuente:** "La información no debe alterarse de forma no autorizada, y una modificación debe poder detectarse. Se protege con funciones de hash, firmas digitales, control de versiones y permisos." (apuntes §2.2).
58: 
59: ### B.2 Confidencialidad — cifrado simétrico
60: 
61: Se cifró el archivo `orden.txt` con GnuPG usando cifrado simétrico (contraseña). Luego se intentó leer el archivo cifrado sin la clave, y finalmente se descifró con la contraseña correcta.
62: 
63: **Código ejecutado:**
64: 
65: ```bash
66: gpg -c orden.txt          # genera orden.txt.gpg
67: cat orden.txt.gpg         # basura binaria
68: gpg -d orden.txt.gpg      # se recupera con la contraseña
69: ```
70: 
71: **Respuesta:**
72: 
73: El cifrado simétrico protege la confidencialidad: el archivo cifrado (`orden.txt.gpg`) es ilegible sin la contraseña. Si alguien roba el archivo cifrado pero no la contraseña, no se violó la confidencialidad, porque el contenido permanece protegido. Sin embargo, si además borra tu única copia, se viola la disponibilidad: ya no podés recuperar el archivo ni con la contraseña. Esto muestra por qué es importante mantener backups de los archivos cifrados.
74: 
75: > **Fuente:** "La información debe ser accesible únicamente para quien está autorizado. Se protege principalmente con cifrado, control de acceso y clasificación de la información." (apuntes §2.1). Disponibilidad: "Se vulnera cuando algo no está (un servidor caído, un backup que nunca se probó)." (apuntes §2.3).
76: 
77: ### B.3 Confidencialidad e integridad — control de acceso
78: 
79: Se inspeccionaron los permisos actuales del archivo `orden.txt` y luego se restringieron para que solo el dueño pueda leer y escribir.
80: 
81: **Código ejecutado:**
82: 
83: ```bash
84: ls -l orden.txt
85: chmod 600 orden.txt
86: ls -l orden.txt           # -rw-------
87: ```
88: 
89: **Respuesta:**
90: 
91: El valor `600` en `chmod` significa: dueño = lectura (4) + escritura (2) = 6; grupo = nada (0); otros = nada (0). Solo el usuario propietario puede leer y modificar el archivo.
92: 
93: Esto aporta a la confidencialidad porque impide que otros usuarios lean el contenido, y aporta a la integridad porque impide que otros lo modifiquen sin autorización. Se relaciona con el principio de **menor privilegio**: cada usuario recibe solo los permisos que necesita, minimizando la superficie de ataque.
94: 
95: > **Fuente:** Elementos del control de acceso: "Autorización: son los permisos asociados al usuario autenticado" (apuntes §Amenazas en el control de acceso). Menor privilegio: "cada usuario o proceso recibe solo los permisos que necesita. Es, probablemente, el principio más rentable" (apuntes §6).
96: 
97: ### B.4 Disponibilidad — el backup que se prueba
98: 
99: Se simuló la pérdida del archivo original y su restauración desde un backup.
100: 
101: **Código ejecutado:**
102: 
103: ```bash
104: cp orden.txt orden.bak
105: rm orden.txt              # "perdimos" el original
106: cp orden.bak orden.txt    # restauramos
107: cat orden.txt
108: ```
109: 
110: **Respuesta:**
111: 
112: El backup protege el pilar de **disponibilidad**: garantiza que la información esté accesible cuando se la necesita, incluso ante la pérdida del original. Sin embargo, un backup que nunca se restauró no cuenta como control efectivo, porque no hay garantía de que funcione cuando se lo necesite. Podría estar corrupto, incompleto o desactualizado.
113: 
114: La regla **3-2-1** (que veremos en la Unidad 2) establece: mantener **3** copias de los datos, en **2** medios diferentes, con **1** copia fuera del sitio. Esto asegura que si un evento destruye una copia (incendio, robo, fallo de disco), siempre exista al menos una alternativa accesible y funcional.
115: 
116: > **Fuente:** "Se vulnera cuando algo no está (un servidor caído, un ataque de denegación de servicio, un backup que nunca se probó). Se protege con redundancia, backups, balanceo de carga y mantenimiento." (apuntes §2.3 – Disponibilidad).
117: 
118: ---
119: 
120: ## Parte C — Del riesgo al control
121: 
122: Se retoma el activo principal de la Parte A: **administración de directorios compartidos**. La amenaza identificada es el acceso no autorizado de un tercero, aprovechando la vulnerabilidad de contraseñas similares.
123: 
124: | Control propuesto | Tipo | Pilar CIA protegido | Descripción |
125: |-------------------|------|---------------------|-------------|
126: | Política de contraseñas robustas + autenticación de dos factores (2FA) | Preventivo | Confidencialidad | Exige contraseñas únicas, complejas y rotativas, y añade un segundo factor de verificación. Ataca directamente la vulnerabilidad de contraseñas similares. |
127: | Registro de auditoría (logs de acceso) | Detectivo | Integridad y Confidencialidad | Registra cada intento de acceso y acción sobre el directorio compartido. Permite detectar en tiempo real si alguien accedió o modificó archivos de forma no autorizada. |
128: 
129: ### Justificación — ¿Cuál implementar primero?
130: 
131: Implementaría primero la **política de contraseñas robustas + 2FA** (preventivo). La razón es que ataca la raíz del problema: la vulnerabilidad de contraseñas similares. Un control preventivo detiene el incidente antes de que ocurra, mientras que un control detectivo solo alerta después de que ya ocurrió daño.
132: 
133: En términos de costo vs. reducción de riesgo: una política de contraseñas no tiene costo tecnológico significativo (se puede implementar con configuración del sistema operativo), y la 2FA tiene costos bajos o gratuitos con herramientas como Google Authenticator. En cambio, un sistema de logs requiere infraestructura de monitoreo, almacenamiento de registros y revisión periódica para ser efectivo.
134: 
135: > **Fuente:** "Un control (o salvaguarda) es toda medida que reduce el riesgo." Tipos: "Preventivo — antes del incidente (Firewall, cifrado, control de acceso)" / "Detectivo — durante el incidente (IDS, monitoreo, logs)" (apuntes §5 – Controles). Menor privilegio: "muchos incidentes graves empiezan con una cuenta que tenía más permisos de los necesarios" (apuntes §6).

(End of file - total 135 lines)
</content>
```

**Tool: read**

**Input:**
```json
{
  "filePath": "C:\\Users\\gonza\\arys\\tps\\2\\consigna.md"
}
```

**Output:**
```
<path>C:\Users\gonza\arys\tps\2\consigna.md</path>
<type>file</type>
<content>
1: # Trabajo Práctico 2 — Seguridad Física
2: 
3: > ARyS · IF046 · UNPSJB Trelew. Modalidad: laboratorio guiado + informe.
4: > Duración estimada: una clase práctica (3 h) + entrega.
5: 
6: ## Objetivos
7: 
8: Al finalizar el práctico, el estudiante será capaz de:
9: 
10: 1. Evaluar los riesgos físicos de un entorno real aplicando defensa en
11:    profundidad y las tres familias de amenazas de la unidad.
12: 2. Implementar y verificar controles a nivel de equipo sobre GNU/Linux: cifrado
13:    de disco, bloqueo de puertos USB y monitoreo de energía.
14: 3. Redactar un plan de mejora priorizado por riesgo, no por intuición.
15: 
16: > **Aclaración ética y legal.** Todas las actividades se realizan sobre
17: > equipamiento propio, de laboratorio o expresamente autorizado. No se aplica
18: > ninguna técnica sobre instalaciones o equipos de terceros sin autorización
19: > escrita.
20: 
21: ---
22: 
23: ## Parte A — Relevamiento de un entorno (individual)
24: 
25: Elegí un entorno real y acotado al que tengas acceso legítimo: la sala de un
26: laboratorio de la facultad, una pyme, tu lugar de trabajo o tu propio espacio
27: de estudio con equipamiento de red.
28: 
29: 1. **Diagramá las capas** de defensa en profundidad presentes (perímetro,
30:    edificio, sala, rack, equipo). Indicá qué capa falta.
31: 2. **Clasificá diez controles** que observes usando la tabla disuasivo /
32:    preventivo / detectivo / correctivo / compensatorio.
33: 3. **Identificá amenazas** por las tres familias:
34:    - Acceso físico no autorizado.
35:    - Desastres naturales (considerá el contexto patagónico: viento, cortes,
36:      ceniza).
37:    - Alteraciones del entorno (energía, clima, cableado).
38: 4. **Registrá tres hallazgos** de mayor riesgo con una foto o croquis (sin
39:    exponer información sensible ni credenciales).
40: 
41: **Entregable A:** informe breve (máx. 2 páginas) con el diagrama de capas, la
42: tabla de controles y los tres hallazgos.
43: 
44: ---
45: 
46: ## Parte B — Controles sobre el equipo (laboratorio)
47: 
48: Trabajá en una **máquina virtual** GNU/Linux descartable. No ejecutes estos
49: comandos sobre tu sistema principal.
50: 
51: ### B.1 Cifrado de disco con LUKS
52: 
53: ```bash
54: # Crear un archivo que oficie de "disco" de laboratorio (2 GB)
55: dd if=/dev/zero of=disco_lab.img bs=1M count=2048
56: sudo losetup /dev/loop20 disco_lab.img
57: 
58: # Cifrar el dispositivo
59: sudo cryptsetup luksFormat /dev/loop20
60: 
61: # Abrirlo, formatearlo y montarlo
62: sudo cryptsetup luksOpen /dev/loop20 caja_fuerte
63: sudo mkfs.ext4 /dev/mapper/caja_fuerte
64: sudo mount /dev/mapper/caja_fuerte /mnt
65: 
66: # Inspeccionar la cabecera LUKS y los slots de clave
67: sudo cryptsetup luksDump /dev/loop20
68: ```
69: 
70: **Consigna B.1.** Guardá un archivo dentro de `/mnt`, desmontá y cerrá el
71: contenedor (`umount /mnt`, `cryptsetup luksClose caja_fuerte`). Demostrá que sin
72: la passphrase el contenido es inaccesible. Explicá con tus palabras qué ataque
73: de la unidad neutraliza el cifrado de disco completo y cuál **no**.
74: 
75: ### B.2 Bloqueo de puertos USB con USBGuard
76: 
77: ```bash
78: sudo apt install usbguard
79: sudo usbguard generate-policy | sudo tee /etc/usbguard/rules.conf
80: sudo systemctl enable --now usbguard
81: 
82: # Ver dispositivos y su estado de autorización
83: usbguard list-devices
84: 
85: # Conectar un pendrive y autorizarlo puntualmente por su número
86: usbguard allow-device <n>
87: ```
88: 
89: **Consigna B.2.** Con la política por defecto en *deny*, conectá un dispositivo
90: USB y mostrá que queda bloqueado hasta autorizarlo. Relacioná esto con el ataque
91: **BadUSB / Rubber Ducky** visto en clase: ¿por qué una lista blanca es más
92: efectiva que una lista negra?
93: 
94: ### B.3 Monitoreo de energía (conceptual o real)
95: 
96: Si disponés de un UPS con Network UPS Tools:
97: 
98: ```bash
99: sudo apt install nut-client
100: upsc ups@localhost
101: ```
102: 
103: Si no disponés de UPS, respondé de forma teórica: dado un servidor crítico con
104: **RTO de 1 hora** y **RPO de 15 minutos**, proponé una configuración de energía
105: (UPS, grupo, redundancia N+1/2N) y una estrategia de backup 3‑2‑1‑1‑0 que
106: cumpla esos objetivos. Justificá cada elección.
107: 
108: **Entregable B:** capturas de pantalla de B.1 y B.2, y las respuestas a las
109: tres consignas.
110: 
111: ---
112: 
113: ## Parte C — Plan de mejora priorizado (individual)
114: 
115: Tomá los hallazgos de la Parte A y construí una tabla de tratamiento del riesgo:
116: 
117: | Hallazgo | Amenaza | Impacto (A/M/B) | Probabilidad (A/M/B) | Control propuesto | Tipo de control | Prioridad |
118: |---|---|---|---|---|---|---|
119: 
120: - Ordená por **riesgo** (impacto × probabilidad), no por costo.
121: - Para cada control propuesto, indicá a qué cláusula de **ISO 27001 Anexo A
122:   cláusula 7** o a qué control **PE de NIST 800‑53** corresponde.
123: 
124: **Entregable C:** tabla completa y un párrafo de conclusión: si tuvieras
125: presupuesto para **un solo** control, ¿cuál implementarías primero y por qué?
126: 
127: ---
128: 
129: ## Entrega y evaluación
130: 
131: - **Formato:** un único PDF con las partes A, B y C. Nombre:
132:   `TP2_ApellidoNombre.pdf`.
133: - **Vía:** campus virtual UNPSJB.
134: - **Criterios de corrección:**
135:   - Correcta aplicación de defensa en profundidad y clasificación de controles (30 %).
136:   - Ejecución y comprensión de los controles de laboratorio B.1–B.3 (35 %).
137:   - Priorización por riesgo y trazabilidad a marcos normativos (25 %).
138:   - Claridad, prolijidad y rigor del informe (10 %).
139: 
140: ## Para investigar (opcional, suma)
141: 
142: - Diferencia entre borrado, sobrescritura y desmagnetizado; por qué la
143:   sobrescritura no alcanza en SSD.
144: - Qué es un ataque **cold boot** y cómo lo mitiga el sellado de claves con TPM.
145: - Cómo se clona una tarjeta de proximidad de 125 kHz y por qué DESFire EV3 no es
146:   vulnerable al mismo ataque.

(End of file - total 146 lines)
</content>
```

---

## Assistant (Build · MiMo V2.5 Free · 41.2s)

_Thinking:_

Now I have a clear picture. The user wants me to create a `solucion.md` file in `tps/2/` with a skeleton following the same style as the TP1 solution. The TP2 is about "Seguridad Física" (Physical Security) and has three parts:

- Part A: Survey of a real environment (layers of defense, controls classification, threats, findings)
- Part B: Team controls on GNU/Linux (LUKS encryption, USBGuard, power monitoring)
- Part C: Prioritized improvement plan

I'll create a skeleton with the same structure as TP1 but adapted for TP2's content, with placeholder sections where the student needs to fill in their own answers.

Voy a crear el esqueleto del `solucion.md` para TP2 siguiendo la misma estructura y estilo que el TP1.

**Tool: write**

**Input:**
```json
{
  "filePath": "C:\\Users\\gonza\\arys\\tps\\2\\solucion.md",
  "content": "# Trabajo Práctico 2 — Seguridad Física\n\n## Parte A — Relevamiento de un entorno\n\n### A.1 Diagrama de capas de defensa en profundidad\n\n**Entorno elegido:** [Describir el entorno: laboratorio, pyme, lugar de trabajo, etc.]\n\n```\n+---------------------+\n|   Perímetro         |  [Qué capa es, qué control tiene]\n+---------------------+\n|   Edificio          |  [Qué capa es, qué control tiene]\n+---------------------+\n|   Sala / Rack       |  [Qué capa es, qué control tiene]\n+---------------------+\n|   Equipo            |  [Qué capa es, qué control tiene]\n+---------------------+\n```\n\n> **Capa faltante:** [Indicar qué capa no está presente y por qué es un riesgo]\n\n### A.2 Clasificación de diez controles\n\n| # | Control observado | Disuasivo | Preventivo | Detectivo | Correctivo | Compensatorio |\n|---|-------------------|:---------:|:----------:|:---------:|:----------:|:-------------:|\n| 1 |                   |           |            |           |            |               |\n| 2 |                   |           |            |           |            |               |\n| 3 |                   |           |            |           |            |               |\n| 4 |                   |           |            |           |            |               |\n| 5 |                   |           |            |           |            |               |\n| 6 |                   |           |            |           |            |               |\n| 7 |                   |           |            |           |            |               |\n| 8 |                   |           |            |           |            |               |\n| 9 |                   |           |            |           |            |               |\n| 10|                   |           |            |           |            |               |\n\n### A.3 Identificación de amenazas por familia\n\n**Familia 1 — Acceso físico no autorizado:**\n\n| Amenaza | Vulnerabilidad | Probabilidad | Impacto |\n|---------|----------------|:------------:|:-------:|\n|         |                |              |         |\n|         |                |              |         |\n\n**Familia 2 — Desastres naturales (contexto patagónico):**\n\n| Amenaza | Vulnerabilidad | Probabilidad | Impacto |\n|---------|----------------|:------------:|:-------:|\n|         |                |              |         |\n|         |                |              |         |\n\n**Familia 3 — Alteraciones del entorno:**\n\n| Amenaza | Vulnerabilidad | Probabilidad | Impacto |\n|---------|----------------|:------------:|:-------:|\n|         |                |              |         |\n|         |                |              |         |\n\n### A.4 Tres hallazgos de mayor riesgo\n\n**Hallazgo 1:**\n\n| Concepto | Valor |\n|----------|-------|\n| Hallazgo | [Descripción del hallazgo] |\n| Amenaza  | [Amenaza asociada] |\n| Vulnerabilidad | [Vulnerabilidad aprovechada] |\n| Probabilidad | [Alta/Media/Baja] |\n| Impacto | [Alta/Media/Baja] |\n\n> **Evidencia:** [Foto o croquis — sin exponer info sensible]\n\n**Hallazgo 2:**\n\n| Concepto | Valor |\n|----------|-------|\n| Hallazgo | [Descripción del hallazgo] |\n| Amenaza  | [Amenaza asociada] |\n| Vulnerabilidad | [Vulnerabilidad aprovechada] |\n| Probabilidad | [Alta/Media/Baja] |\n| Impacto | [Alta/Media/Baja] |\n\n> **Evidencia:** [Foto o croquis — sin exponer info sensible]\n\n**Hallazgo 3:**\n\n| Concepto | Valor |\n|----------|-------|\n| Hallazgo | [Descripción del hallazgo] |\n| Amenaza  | [Amenaza asociada] |\n| Vulnerabilidad | [Vulnerabilidad aprovechada] |\n| Probabilidad | [Alta/Media/Baja] |\n| Impacto | [Alta/Media/Baja] |\n\n> **Evidencia:** [Foto o croquis — sin exponer info sensible]\n\n---\n\n## Parte B — Controles sobre el equipo (laboratorio)\n\n### B.1 Cifrado de disco con LUKS\n\n**Código ejecutado:**\n\n```bash\n# Crear un archivo que oficie de \"disco\" de laboratorio (2 GB)\ndd if=/dev/zero of=disco_lab.img bs=1M count=2048\nsudo losetup /dev/loop20 disco_lab.img\n\n# Cifrar el dispositivo\nsudo cryptsetup luksFormat /dev/loop20\n\n# Abrirlo, formatearlo y montarlo\nsudo cryptsetup luksOpen /dev/loop20 caja_fuerte\nsudo mkfs.ext4 /dev/mapper/caja_fuerte\nsudo mount /dev/mapper/caja_fuerte /mnt\n\n# Inspeccionar la cabecera LUKS y los slots de clave\nsudo cryptsetup luksDump /dev/loop20\n```\n\n**Captura del luksDump:**\n\n> [Insertar captura de pantalla aquí]\n\n**Demostración de inaccesibilidad sin passphrase:**\n\n```bash\n# Desmontar y cerrar\nsudo umount /mnt\nsudo cryptsetup luksClose caja_fuerte\n\n# Intentar acceder al contenido sin la passphrase\nsudo cryptsetup luksOpen /dev/loop20 caja_fuerte\n# [Capturar resultado del intento]\n```\n\n> [Insertar captura mostrando que sin la passphrase el contenido es inaccesible]\n\n**Respuesta:**\n\n¿Qué ataque neutraliza el cifrado de disco completo y cuál **no**?\n\n- **Ataque que SÍ neutraliza:** [Explicar — ej. robo físico del disco, acceso no autorizado al equipo apagado]\n- **Ataque que NO neutraliza:** [Explicar — ej. ataque en memoria cuando el disco está descifrado y montado, cold boot attack]\n\n> **Fuente:** [Referencia a apuntes o bibliografía sobre cifrado de disco]\n\n### B.2 Bloqueo de puertos USB con USBGuard\n\n**Código ejecutado:**\n\n```bash\nsudo apt install usbguard\nsudo usbguard generate-policy | sudo tee /etc/usbguard/rules.conf\nsudo systemctl enable --now usbguard\n\n# Ver dispositivos y su estado de autorización\nusbguard list-devices\n\n# Conectar un pendrive y autorizarlo puntualmente por su número\nusbguard allow-device <n>\n```\n\n**Captura de usbguard list-devices (antes de autorizar):**\n\n> [Insertar captura mostrando el dispositivo bloqueado]\n\n**Captura de usbguard list-devices (después de autorizar):**\n\n> [Insertar captura mostrando el dispositivo autorizado]\n\n**Respuesta:**\n\n¿Por qué una lista blanca es más efectiva que una lista negra contra BadUSB / Rubber Ducky?\n\n- [Explicar el principio de lista blanca vs lista negra]\n- [Relacionar con el ataque BadUSB: el dispositivo se identifica falsamente como teclado]\n- [Por qué la lista blanca impide que dispositivos no reconocidos se ejecuten automáticamente]\n\n> **Fuente:** [Referencia a apuntes sobre BadUSB y control de dispositivos]\n\n### B.3 Monitoreo de energía\n\n> **Nota:** Si no disponés de UPS con Network UPS Tools, desarrollar la respuesta teórica.\n\n**Servidor crítico:**\n- **RTO:** 1 hora\n- **RPO:** 15 minutos\n\n**Configuración de energía propuesta:**\n\n| Componente | Elección | Justificación |\n|------------|----------|---------------|\n| UPS         | [Marca/modelo/capacidad] | [Por qué esa capacidad] |\n| Grupo electrógeno | [Sí/No, especificación] | [Por qué se necesita o no] |\n| Redundancia | [N+1 / 2N / otra] | [Por qué esa configuración] |\n\n**Estrategia de backup 3-2-1-1-0:**\n\n| Nivel | Descripción | Implementación |\n|-------|-------------|----------------|\n| **3** copias | [Cómo se logran] | |\n| **2** medios | [Qué medios se usan] | |\n| **1** fuera del sitio | [Dónde se ubica] | |\n| **1** off-line / inmutable | [Cómo se protege] | |\n| **0** errores | [Cómo se verifica] | |\n\n**Respuesta:**\n\n[Justificar cada elección en función del RTO de 1 hora y RPO de 15 minutos]\n\n> **Fuente:** [Referencia a apuntes sobre disponibilidad, RTO/RPO y regla 3-2-1]\n\n---\n\n## Parte C — Plan de mejora priorizado\n\n### Tabla de tratamiento del riesgo\n\n| Hallazgo | Amenaza | Impacto (A/M/B) | Probabilidad (A/M/B) | Control propuesto | Tipo de control | Cláusula ISO 27001 / Control NIST 800-53 | Prioridad |\n|----------|---------|:----------------:|:--------------------:|-------------------|-----------------|--------------------------------------------|:---------:|\n|          |         |                  |                      |                   |                 |                                            |           |\n|          |         |                  |                      |                   |                 |                                            |           |\n|          |         |                  |                      |                   |                 |                                            |           |\n|          |         |                  |                      |                   |                 |                                            |           |\n\n> **Ordenamiento:** por riesgo (impacto × probabilidad), no por costo.\n\n### Conclusión\n\n**Si tuviera presupuesto para un solo control, implementaría primero:**\n\n[Indicar el control elegido y justificar por qué, considerando:]\n\n- Qué amenaza / hallazgo mitiga directamente\n- Por qué tiene mejor relación costo-beneficio\n- A qué pilar CIA protege\n- Qué cláusula ISO 27001 o control NIST respalda la decisión\n\n> **Fuente:** [Referencia a marcos normativos y apuntes]\n\n---\n\n## Para investigar (opcional)\n\n### Diferencia entre borrado, sobrescritura y desmagnetizado\n\n> [Desarrollar]\n\n### Ataque cold boot y mitigación con TPM\n\n> [Desarrollar]\n\n### Clonación de tarjetas de proximidad y por qué DESFire EV3 no es vulnerable\n\n> [Desarrollar]\n"
}
```

**Output:**
```
Wrote file successfully.
```

---

## Assistant (Build · MiMo V2.5 Free · 6.8s)

_Thinking:_

The file has been created. Let me give a brief summary to the user.

Listo, creé `tps/2/solucion.md` con el esqueleto completo. Mantiene la misma estructura y estilo que el TP1:

- **Parte A:** Espacios para el diagrama de capas, tabla de 10 controles, amenazas por las 3 familias, y los 3 hallazgos con formato de tabla.
- **Parte B:** Bloques de código, espacios para capturas, y secciones de respuesta para B.1 (LUKS), B.2 (USBGuard) y B.3 (energía/backup 3-2-1-1-0).
- **Parte C:** Tabla de tratamiento del riesgo con columna para ISO 27001 / NIST, y sección de conclusión.
- **Para investigar:** Secciones vacías para los temas opcionales.

---

## User

como le agrego una imagen a la solución?

---

## Assistant (Build · MiMo V2.5 Free · 13.0s)

_Thinking:_

The user is asking how to add an image to the solution.md file. This is a straightforward question about markdown syntax.

En markdown se usa la sintaxis `![alt text](ruta)`:

```markdown
![Descripción de la imagen](ruta/relativa/imagen.png)
```

Por ejemplo, para el TP2:

```markdown
![Diagrama de capas de defensa](hallazgo1.jpg)
```

Si la imagen está en la misma carpeta que `solucion.md` (es decir, `tps/2/`), poné el nombre directo. Si está en subcarpeta, usá `subcarpeta/imagen.png`.

---

## User

que otros controles podría haber a parte de los que agregué? Dame ideas

---

## Assistant (Plan · MiMo V2.5 Free · 11.2s)

_Thinking:_

The user is asking for ideas about additional controls they could include in their TP2 (physical security) solution. This is a straightforward knowledge question - I can answer directly without needing to search the codebase or make any changes. I'm in plan mode but this is just a conversational question, not a task requiring file modifications.

Let me think about physical security controls beyond what's typically covered in basic security courses.

Te doy ideas organizadas por las categorías del TP2:

**Disuasivos:**
- Señalización de vigilancia 24/7 (aunque sea falsa)
- Alarma externa visible con sirena
- Iluminación perimetral con sensor de movimiento

**Preventivos:**
- Cerraduras electrónicas con tarjeta/proximidad
- Biometría (huella dactilar, reconocimiento facial)
- Control de acceso con registro de entrada/salida
- Server rack con cerradura física
- Videocámara con grabación en CCTV

**Detectivos:**
- Sensores de apertura de puertas/ventanas
- Sensores de movimiento en sala de servidores
- Sistema de monitoreo de temperatura/humedad
- Registro de logs de acceso físico (quién entra y cuándo)
- Detector de humo/incendio

**Correctivos:**
- Extintores y sistema de supresión de incendios (gas, no agua)
- Plan de evacuación documentado
- UPS + grupo electrógeno (ya lo tenés en B.3)
- Protocolo de respuesta ante incidentes físicos

**Compensatorios:**
- VPN para acceso remoto (evita ir presencialmente)
- Copias off-site / en la nube
- Seguro contra desastres naturales

Para el contexto patagónico, no olvides: sensores de ceniza volcánica, protección contra cortes de energía frecuentes, y ventanas reforzadas contra viento zonal.

---

## User

Qué ejemplos de amenaza podría haber en el entorno que describí en la solución? Utiliza la definición estricta dada en la bibliografía

---

## Assistant (Plan · MiMo V2.5 Free · 6.3s)

_Thinking:_

The user is asking about examples of threats for the physical environment they described in the TP2 solution. They want me to use the strict definition from the bibliography. Let me check the bibliography and apuntes to understand the exact definition of "amenaza" they're referring to.

Voy a revisar la bibliografía y apuntes para darte la definición exacta de amenaza.

**Tool: glob**

**Input:**
```json
{
  "pattern": "apuntes/**/*"
}
```

**Output:**
```
C:\Users\gonza\arys\apuntes\unidad-01-teoria-web.md
C:\Users\gonza\arys\apuntes\unidad-01-conceptos-de-seguridad.md
```

**Tool: glob**

**Input:**
```json
{
  "pattern": "bibliografia/**/*"
}
```

**Output:**
```
C:\Users\gonza\arys\bibliografia\unidad-02-seguridad-fisica.md
C:\Users\gonza\arys\bibliografia\unidad-01-teoria-web.txt
C:\Users\gonza\arys\bibliografia\unidad-01-conceptos-de-seguridad.pdf
```

---

## Assistant (Plan · MiMo V2.5 Free · 3.5s)

_Thinking:_

Let me check the bibliography for unidad 2 (physical security) and the apuntes to find the strict definition of "amenaza".

**Tool: read**

**Input:**
```json
{
  "filePath": "C:\\Users\\gonza\\arys\\bibliografia\\unidad-02-seguridad-fisica.md"
}
```

**Output:**
```
<path>C:\Users\gonza\arys\bibliografia\unidad-02-seguridad-fisica.md</path>
<type>file</type>
<content>
1: # Unidad 2 — Seguridad Física
2: 
3: > Material teórico de acompañamiento. Complementa las filminas y la clase.
4: > ARyS · IF046 · UNPSJB Trelew.
5: 
6: ## 1. Por qué la seguridad física es la base
7: 
8: En la Unidad 1 definimos la seguridad de la información sobre seis pilares:
9: confidencialidad, integridad, disponibilidad, autenticidad, no repudio y
10: privacidad. Todos ellos se implementan mediante **controles lógicos** —
11: contraseñas, cifrado, firewalls, permisos— que se ejecutan sobre **hardware
12: físico**.
13: 
14: De ahí el axioma que ordena toda esta unidad:
15: 
16: > Si un atacante obtiene acceso físico irrestricto a un equipo, ese equipo
17: > deja de ser confiable.
18: 
19: Es una de las *10 Immutable Laws of Security* de Microsoft y sigue vigente:
20: quien controla el hardware controla la ejecución del software que lo protege.
21: Puede reiniciar desde otro medio, extraer el disco, intervenir el arranque o
22: implantar hardware. La seguridad física es, por lo tanto, el **primer
23: perímetro** y la precondición de todos los demás controles.
24: 
25: ## 2. Qué protegemos
26: 
27: La seguridad física no protege solo servidores. El alcance incluye:
28: 
29: - **Personas** — prioridad absoluta; ningún activo justifica un riesgo de vida.
30: - **Instalaciones** — edificio, sala técnica, centro de datos.
31: - **Equipamiento** — servidores, equipos de red, estaciones de trabajo, móviles.
32: - **Medios de almacenamiento** — discos, cintas, unidades removibles, backups.
33: - **Infraestructura de soporte** — energía, refrigeración, cableado.
34: - **Documentación** — planos, credenciales, contratos, información en papel.
35: 
36: ## 3. Las tres familias de amenazas
37: 
38: El programa organiza la seguridad física en tres tipos de amenaza. Conviene
39: tenerlas separadas porque las contramedidas son distintas.
40: 
41: ### 3.1 Acceso físico no autorizado (intencional)
42: 
43: Una persona ingresa a un espacio o accede a un equipo sin autorización. Es la
44: amenaza con **agente deliberado**. Se combate con **defensa en profundidad**:
45: capas concéntricas de control, cada una de las cuales retrasa al atacante y
46: genera evidencia.
47: 
48: Las capas típicas, de afuera hacia adentro:
49: 
50: 1. **Perímetro** — cerco, portón, iluminación, vigilancia.
51: 2. **Edificio** — recepción, control de visitas, torniquete.
52: 3. **Sala técnica** — esclusa (mantrap), control de acceso por doble factor.
53: 4. **Rack** — jaula o gabinete con cerradura.
54: 5. **Equipo** — cifrado de disco, TPM, bloqueo de puertos.
55: 
56: Los controles se clasifican por su función:
57: 
58: | Tipo | Propósito | Ejemplo |
59: |---|---|---|
60: | Disuasivo | Desalentar el intento | Cartelería, iluminación, garita |
61: | Preventivo | Impedir el hecho | Cerradura, esclusa, jaula |
62: | Detectivo | Descubrir el hecho | CCTV, sensores, alarmas |
63: | Correctivo | Restaurar tras el hecho | Backup, repuestos, sitio alterno |
64: | Compensatorio | Sustituir otro control | Guardia 24×7 |
65: 
66: Un principio de diseño complementario es **CPTED** (*Crime Prevention Through
67: Environmental Design*): control natural de accesos, vigilancia natural,
68: refuerzo territorial y mantenimiento. Es el control más económico porque se
69: decide en la etapa de planos.
70: 
71: #### Mecanismos de control de acceso
72: 
73: Se basan en los mismos factores de autenticación que veremos en la Unidad 7,
74: aplicados al mundo físico:
75: 
76: - **Algo que se sabe** — PIN.
77: - **Algo que se tiene** — llave, tarjeta de proximidad, token.
78: - **Algo que se es** — biometría (huella, iris, rostro, geometría de mano).
79: 
80: La **biometría** merece una advertencia doble: no es secreta (dejamos huellas y
81: rostro por todos lados) y **no es revocable** (no se puede "cambiar de dedo" si
82: se filtra la plantilla). Sus métricas clave son FAR (tasa de falsa aceptación,
83: riesgo de seguridad), FRR (tasa de falso rechazo, riesgo de disponibilidad) y
84: CER/EER (punto de cruce, útil para comparar sistemas). Debe usarse como **un**
85: factor, nunca como el único.
86: 
87: #### Ataques al acceso físico
88: 
89: - **Tailgating** — seguir a una persona autorizada sin credencial propia.
90: - **Piggybacking** — igual, pero con consentimiento del autorizado.
91: - **Lockpicking / bumping** — apertura de cerraduras.
92: - **Clonado RFID** — copia de tarjetas de baja frecuencia (125 kHz) con
93:   Proxmark3 o Flipper Zero.
94: - **Shoulder surfing** — observación del PIN.
95: - **Dumpster diving** — recuperación de información de la basura.
96: 
97: La mayoría de las intrusiones reales explotan el **factor humano** mediante
98: ingeniería social: una credencial impresa y una excusa creíble superan casi
99: cualquier control técnico. La contramedida es procedimental y cultural:
100: procedimiento de visitas, acompañamiento obligatorio y una cultura donde
101: verificar y preguntar sea la norma.
102: 
103: #### Ataques al equipo con acceso físico
104: 
105: - **Arranque alternativo** — booteo desde USB o red para eludir el sistema.
106: - **Extracción de disco** — leer los datos en otra máquina.
107: - **Evil maid** — manipulación del gestor de arranque en una ausencia breve.
108: - **Cold boot** — recuperación de claves desde la RAM enfriada.
109: - **BadUSB / Rubber Ducky** — dispositivo que se presenta como teclado y ejecuta
110:   comandos; requiere segundos.
111: - **DMA** — acceso directo a memoria por Thunderbolt/PCIe.
112: - **JTAG / UART** — acceso a la consola de depuración de la placa.
113: 
114: Contramedidas a nivel de equipo: cifrado de disco completo (LUKS), contraseña
115: de firmware con orden de arranque fijo, Secure Boot, TPM 2.0 para sellar la
116: clave al estado del arranque, protección DMA (IOMMU), bloqueo de puertos USB
117: (USBGuard con política de lista blanca) y detección de apertura de gabinete.
118: 
119: ### 3.2 Desastres naturales (no intencional)
120: 
121: Amenazas sin agente deliberado: incendio, inundación, sismo, viento, actividad
122: volcánica. La primera contramedida es la **ubicación**: evitar sótanos
123: (inundación), últimas plantas (temperatura, filtraciones) y proximidad a baños,
124: cocinas o cañerías.
125: 
126: En el contexto **patagónico**, el perfil de riesgo dominante no es el sismo sino
127: el **viento fuerte, los cortes de energía prolongados y la ceniza volcánica**.
128: La ceniza es abrasiva y conductiva: daña ventiladores, filtros y fuentes de
129: alimentación, y obliga a presurización positiva de sala y filtrado reforzado.
130: 
131: Controles principales:
132: 
133: - **Fuego** — detección temprana por aspiración (VESDA), detectores de humo y
134:   térmicos, extinción por agente limpio (NOVEC 1230, FM-200, INERGEN). Nunca
135:   agua ni polvo químico en sala de servidores. Corte automático de energía y
136:   HVAC al disparar la extinción.
137: - **Agua** — sensores de humedad bajo piso técnico, ausencia de cañerías sobre
138:   los racks, piso elevado con desagüe.
139: - **Sismo** — anclaje de racks, aisladores de base, sujeción de cargas altas.
140: - **Viento y ceniza** — sellado de aberturas, presurización, filtros F7/F9.
141: 
142: La respuesta a desastres se planifica con métricas de continuidad:
143: 
144: - **RTO** (*Recovery Time Objective*) — tiempo máximo tolerable de caída.
145: - **RPO** (*Recovery Point Objective*) — pérdida máxima tolerable de datos.
146: - **BIA** (*Business Impact Analysis*) — análisis que identifica procesos
147:   críticos y el costo de su interrupción; de él sale el presupuesto de todos los
148:   controles.
149: 
150: Los **sitios alternos** (cold, warm, hot, cloud/DRaaS) y la política de
151: **backups** completan la estrategia. La regla mínima es **3‑2‑1** (tres copias,
152: dos medios, una fuera del sitio), extendida a **3‑2‑1‑1‑0** para incluir una
153: copia inmutable/offline contra ransomware y cero errores en una restauración
154: **probada**. Un backup nunca restaurado no es un backup.
155: 
156: ### 3.3 Alteraciones del entorno (no intencional)
157: 
158: Fallas de las condiciones ambientales que rompen sin dejar marca visible.
159: 
160: #### Energía eléctrica
161: 
162: Fenómenos: blackout (corte total), brownout (baja tensión sostenida), sag
163: (caída breve), surge/spike (sobretensión), ruido/EMI (interferencia). La defensa
164: combina **UPS** (estabilización y autonomía corta), **grupo electrógeno**
165: (autonomía larga), puesta a tierra correcta y protección contra sobretensión.
166: 
167: El UPS no está para cubrir toda la noche: está para sostener hasta que arranque
168: el grupo o para permitir un apagado ordenado. El grupo debe probarse **con
169: carga** y las baterías deben medirse (vida útil 3–5 años).
170: 
171: La **redundancia** se expresa como N, N+1, 2N o 2N+1. Advertencia frecuente: dos
172: fuentes conectadas a la misma regleta no son redundancia.
173: 
174: #### Clima
175: 
176: Rango recomendado por **ASHRAE**: temperatura 18–27 °C, humedad relativa
177: 40–60 %. Humedad baja → electricidad estática; humedad alta → condensación y
178: corrosión. El esquema **pasillo frío / pasillo caliente** con contención evita
179: que el aire frío y el caliente se mezclen.
180: 
181: #### Cableado y emanaciones
182: 
183: El cableado es parte de la seguridad: canalizaciones cerradas y rotuladas, patch
184: panel bajo llave, separación de datos y energía, y **puertos de switch sin uso
185: deshabilitados**. Un *network tap* pasivo en un patch panel descuidado copia
186: todo el tráfico sin alterar el enlace (tema que retomaremos en la Unidad 4).
187: 
188: Las **emanaciones electromagnéticas** (TEMPEST) son un canal lateral: monitores,
189: cables y teclados irradian señal recuperable. Es una amenaza de alto costo y
190: objetivos de alto valor; para el curso vale como concepto: el canal lateral
191: existe aunque no se lo vea.
192: 
193: ## 4. Marcos de referencia
194: 
195: Dos marcos ordenan los controles físicos y sirven como lista de verificación al
196: diseñar:
197: 
198: - **ISO/IEC 27001:2022**, Anexo A, cláusula 7 (Controles físicos): perímetros,
199:   ingreso, áreas seguras, monitoreo, protección frente a amenazas físicas,
200:   escritorio y pantalla limpios, equipamiento, cableado, mantenimiento y
201:   descarte seguro.
202: - **NIST SP 800‑53 Rev. 5**, familia **PE** (*Physical and Environmental
203:   Protection*): autorizaciones, control de acceso, monitoreo, energía, fuego,
204:   clima y sitio alterno.
205: 
206: Complementan la unidad las prácticas de **clean desk / clean screen** y el
207: **descarte seguro de medios**: papel a destructora de corte cruzado, discos
208: magnéticos por borrado o desmagnetizado, y SSD por borrado criptográfico (la
209: sobrescritura no es suficiente en memoria flash).
210: 
211: ## 5. Ideas para llevarse
212: 
213: 1. El acceso físico derrota al control lógico.
214: 2. Se defiende en capas, y cada capa debe dejar registro.
215: 3. Prevenir, detectar y responder: las tres funciones, no una sola.
216: 4. El BIA define cuánto invertir; decide el riesgo, no el miedo.
217: 5. La disponibilidad se sostiene en energía, clima y backups probados.
218: 6. El eslabón humano abre más puertas que cualquier ganzúa.
219: 
220: ## 6. Referencias
221: 
222: - Microsoft — *Ten Immutable Laws of Security*.
223: - ISO/IEC 27001:2022 — Anexo A, controles físicos (cláusula 7).
224: - NIST SP 800‑53 Rev. 5 — familia PE.
225: - ASHRAE TC 9.9 — *Thermal Guidelines for Data Processing Environments*.
226: - W. Stallings — *Fundamentos de Seguridad en Redes* (bibliografía de cátedra).

(End of file - total 226 lines)
</content>
```

**Tool: read**

**Input:**
```json
{
  "filePath": "C:\\Users\\gonza\\arys\\apuntes\\unidad-01-conceptos-de-seguridad.md"
}
```

**Output:**
```
<path>C:\Users\gonza\arys\apuntes\unidad-01-conceptos-de-seguridad.md</path>
<type>file</type>
<content>
1: # Administración de Redes y Seguridad
2: 
3: ## Unidad 1 - Conceptos de Seguridad
4: 
5: ---
6: 
7: ### Información
8: 
9: Temas: Información, Seguridad, Privacidad, Confidencialidad, Integridad, Autenticidad, No repudio.
10: 
11: - ¿Qué se debe asegurar?
12:   - Los activos de la organización.
13: - ¿Qué lugar ocupa la información?
14:   - La información constituye un lugar muy importante en la organización ya que tiene un rol fundamental a la hora de cumplir sus objetivos.
15: - ¿Qué significa garantizar la seguridad de la información?
16:   - Significa proteger la información y los sistemas de información del acceso, uso, divulgación, interrupción, modificación o destrucción no autorizadas.
17: - ¿Qué significa garantizar la privacidad de la información?
18:   - Significa no revelar la información, o revelarla selectivamente, para protegerla de cualquier intromisión.
19: 
20: ---
21: 
22: ### Desafío
23: 
24: - ¿Tenés un smartphone con android?
25: - ¿Te acordás donde estuviste hace un mes?
26: - Preguntale al servicio Location History de Google.
27: - Otro ejemplo: ¿Por qué me vigilan si no soy nadie? | Marta Peirano | TEDxMadrid
28: 
29: ---
30: 
31: ### Categorías de ataques
32: 
33: - Interrupción
34:   - Ataque a la disponibilidad.
35: - Intercepción
36:   - Ataque a la confidencialidad.
37: - Modificación
38:   - Ataque a la integridad.
39: - Fabricación
40:   - Ataque a la autenticidad.
41: 
42: ---
43: 
44: ### Vulnerabilidades y Amenazas
45: 
46: - Una vulnerabilidad es una debilidad en un activo.
47: - Una amenaza es una violación potencial de una vulnerabilidad.
48: 
49: ---
50: 
51: ### Tipos de Amenazas
52: 
53: - Naturales
54:   - Incendios.
55:   - Terremotos.
56:   - Inundaciones.
57: - Humanas
58:   - Maliciosas
59:     - Internas.
60:     - Externas.
61:   - No maliciosas
62:     - Impericia.
63: 
64: ---
65: 
66: ### Incidente de Seguridad
67: 
68: Un incidente de seguridad es el evento adverso que afecta los activos de la organización.
69: 
70: Todo incidente debe ser reportado a quien corresponda.
71: 
72: Categorías de ataques:
73: 
74: - Interrupción
75:   - Ataque a la disponibilidad.
76: - Intercepción
77:   - Ataque a la confidencialidad.
78: - Modificación
79:   - Ataque a la integridad.
80: - Fabricación
81:   - Ataque a la autenticidad.
82: 
83: ---
84: 
85: ### Amenazas - Conceptos generales
86: 
87: - Las amenazas atentan contra:
88:   - La confidencialidad de la información.
89:   - La integridad de la información.
90:   - La disponibilidad de la información.
91: - Son causadas por:
92:   - Fallas humanas.
93:   - Ataques malintencionados.
94:   - Catástrofes naturales.
95: 
96: La materialización de una amenaza puede causar:
97: 
98: - El acceso, robo modificación o eliminación no autorizadas de información.
99: - La interrupción de un servicio o el procesamiento de un sistema.
100: - Daños físicos o robo del equipamiento y medios de almacenamiento de información.
101: 
102: ---
103: 
104: ### Amenazas sobre las personas - Ingeniería Social
105: 
106: - La Ingeniería Social es una conjunto de trucos, engaños o artimañas que permiten confundir a una persona para que entregue información confidencial.
107: - La principal defensa contra la ingeniería social es la concientización en la implementación de políticas de seguridad.
108: 
109: #### ¿Por qué funciona?
110: 
111: Según Kevin Mitnick, uno de los ingenieros sociales más famosos de los últimos tiempos, la ingeniería social se basa en estos cuatro principios:
112: 
113: - Todos queremos ayudar.
114: - El primer movimiento es siempre de confianza hacia el otro.
115: - No nos gusta decir "No".
116: - A todos nos gusta que nos alaben.
117: 
118: > "La Seguridad muchas veces es una mera Ilusión. Una compañía puede tener la mejor tecnología, firewalls, sistemas de detección de intrusos, dispositivos de autenticación avanzados como tarjetas biométricas, etc y creen que están asegurados 100%. Viven una Ilusión. Sólo se necesita un llamado telefónico y listo. Ya son vulnerables a un ataque. La Seguridad no es un producto, es un Proceso"
119: >
120: > — Kevin Mitnik
121: 
122: ---
123: 
124: ### Amenazas sobre las personas - Phishing y Pharming
125: 
126: - El Phishing es una combinación de ingeniería social y elementos técnicos para engañar a un usuario y lograr que éste entregue involuntariamente información confidencial a usuarios malintencionados. La forma más común es mediante el envío de mails falsos, escritos como si hubieran sido enviados por la auténtica organización.
127: - El Pharming consiste en alterar la asociación de nombre (www.mibanco.com) a dirección real (IP) para dirigir a un usuario a una dirección que no es la verdadera. Puede ser desconcertante ya que el usuario escribe por si mismo la dirección de la página web.
128: 
129: ---
130: 
131: ### Amenazas sobre las personas - Spam
132: 
133: También llamado "Correo Basura". Es uno de los principales medios para hacer llegar todo tipo de problemas a los usuarios del correo electrónico.
134: 
135: Se utiliza para:
136: 
137: - Publicidad no deseada.
138: - Phishing (se vale de la ingeniería social).
139: - Transmisión de código malicioso.
140: 
141: ---
142: 
143: ### Amenazas sobre las personas - Hoax
144: 
145: Son mensajes de correo electrónico engañosos que se distribuyen en cadena. Algunos tienen textos alarmantes sobre catástrofes (virus informáticos, perder el trabajo o incluso la muerte) que puede suceder si no se reenvía el mensaje o se hace lo que el mismo indica. La motivación de un hoax es recolectar direcciones de correo y otros datos confidenciales.
146: 
147: ---
148: 
149: ### Amenazas en el control de acceso
150: 
151: Elementos del control de acceso:
152: 
153: - Identificación: es una secuencia de caracteres que identifica unívocamente al usuario: nombre de usuario.
154: - Autenticación: es la verificación que realiza el sistema sobre la identificación. Se puede realizar a través de:
155:   - Algo que se conoce: clave de acceso.
156:   - Algo que se posee: tokens / tarjeta.
157:   - Algo que se es: huella digital, iris, retina, voz.
158: - Autorización: son los permisos asociados al usuario autenticado.
159: 
160: ---
161: 
162: ### Ataques de contraseñas
163: 
164: Consiste en la prueba metódica de contraseñas para lograr el acceso a un sistema, siempre y cuando la cuenta no presente control de intentos fallidos de logueo. Este tipo de ataque puede ser realizado:
165: 
166: - Por diccionario: existiendo un diccionario de palabras, una herramienta intentará acceder al sistema probando una a una las palabras incluidas en el mismo.
167: - Por fuerza bruta: una herramienta generará combinaciones de letras, números y símbolos formando posibles contraseñas y probando una a una en el login del sistema.
168: 
169: ---
170: 
171: ### Más ejemplos de amenazas
172: 
173: Acceso no autorizado a información sensible, como puede ser:
174: 
175: - Información confidencial impresa.
176: - Información confidencial guardada en medios de almacenamiento removibles (CDs, DVDs, pendrives).
177: - Información confidencial almacenada en notebooks.
178: 
179: ---
180: 
181: ### Código Malicioso (Malware)
182: 
183: Virus/Gusanos/Troyanos/Spyware/Keyloggers:
184: 
185: - Destruyen datos.
186: - Consumen recursos del equipo.
187: - Permiten acceso de extraños al equipo.
188: - Roban información (números de cuentas, claves, información financiera).
189: - Roban nuestra identidad.
190: 
191: Los antivirus/antispyware nos protegen del malware, pero no nos cubren de todos los riesgos, es por ello que debemos tomar precauciones.
192: 
193: ---
194: 
195: ### Malware - ¿Cómo llega a nuestro equipo?
196: 
197: Sin nuestro consentimiento:
198: 
199: - Navegando por sitios de Internet que descargan su código malicioso en navegadores mal configurados y/o desactualizados.
200: 
201: Con nuestro consentimiento:
202: 
203: - Instalando algún Freeware (programa gratuito). Al aceptar sus condiciones de uso (generalmente en inglés y que nunca se leen) comienzan a funcionar como espías.
204: - Siendo víctimas de Ingeniería social.
205: 
206: ---
207: 
208: ### Buenas Prácticas
209: 
210: Como administradores/desarrolladores:
211: 
212: - Siguiendo las buenas prácticas de seguridad que indican los estándares / normas nacionales e internacionales.
213: - Aprobando la materia :D
214: 
215: ---
216: 
217: ### Concientización
218: 
219: Un programa de concientización de Seguridad resulta fundamental para fortalecer los eslabones más débiles de la cadena de seguridad, las personas por:
220: 
221: - Desconocimiento de las amenazas.
222: - Desconocimiento de las medidas de seguridad.
223: - Desconocimiento de los roles y responsabilidades de cada persona, con respecto a la seguridad.
224: 
225: Este programa debe estar dirigido a todo el personal que trabaje con información de la organización.
226: 
227: El programa de concientización debe incluir:
228: 
229: - Acciones de impacto, como ser:
230:   - Sesiones de concientización para los directivos.
231:   - Sesiones de concientización para personal de TI.
232:   - Sesiones de concientización para usuarios finales.
233: - Acciones de seguimiento, como ser:
234:   - Eventos de seguirdad.
235:   - Boletines Internos.
236:   - Posters.
237:   - Tips para la navegación.
238: 
239: El programa de concientización debe ser realizado a medida, teniendo en cuenta perfil de la empresa, tareas que se realizan y rasgos del personal.
240: 
241: Las actividades/ejemplos deben relacionarse con las actividades diarias del personal.
242: 
243: ---
244: 
245: Fin Unidad 1.

(End of file - total 245 lines)
</content>
```

---

## Assistant (Plan · MiMo V2.5 Free · 11.0s)

_Thinking:_

Now I have the definitions. From the bibliography and apuntes:

From unidad-01-conceptos-de-seguridad.md:
- "Una vulnerabilidad es una debilidad en un activo."
- "Una amenaza es una violación potencial de una vulnerabilidad."

And the types of threats:
- Naturales (Incendios, Terremotos, Inundaciones)
- Humanas maliciosas (internas/externas)
- Humanas no maliciosas (impericia)

From unidad-02-seguridad-fisica.md, the three families are:
1. Acceso físico no autorizado (intencional)


2. Desastres naturales (no intencional)
3. Alteraciones del entorno (no intencional)

So the user is looking for specific threat examples within each of these three categories for their particular environment, grounded in these formal definitions from the coursework.

Según la bibliografía, las definiciones clave son:

- **Vulnerabilidad:** "debilidad en un activo"
- **Amenaza:** "violación potencial de una vulnerabilidad"

Y las tres familias del TP2 las clasifica así (bibliografía §3):

1. **Acceso físico no autorizado** — agente deliberado
2. **Desastres naturales** — sin agente deliberado
3. **Alteraciones del entorno** — sin agente deliberado

---

Ejemplos concretos para cada familia:

**Familia 1 — Acceso físico no autorizado:**

| Amenaza | Vulnerabilidad que aprovecha |
|---------|------------------------------|
| Tailgating / Piggybacking | Puerta de acceso sin control de turno |
| Clonado RFID de tarjeta de proximidad | Tarjetas de 125 kHz sin cifrado |
| Robo de disco portátil | Discos sin cifrado (LUKS) |
| Evil maid attack | Equipo encendido sin bloqueo de sesión |
| Ingeniería social al personal de limpieza | Falta de protocolo de acompañamiento |
| Dumpster diving | Residuos de papel con datos sin destruir |

**Familia 2 — Desastres naturales (contexto patagónico):**

| Amenaza | Vulnerabilidad que aprovecha |
|---------|------------------------------|
| Ceniza volcánica | Filtros de aire sin presurización ni sellado |
| Viento zonal fuerte | Aberturas sin refuerzo, cableado expuesto |
| Cortes prolongados de energía | Sin UPS ni grupo electrógeno |
| Inundación por deshielo | Servidores en planta baja o sótano |

**Familia 3 — Alteraciones del entorno:**

| Amenaza | Vulnerabilidad que aprovecha |
|---------|------------------------------|
| Brownout / sag de tensión | Equipos sin estabilizador o UPS |
| Temperatura fuera de rango ASHRAE (18–27 °C) | Sala sin climatización o sin monitoreo |
| Humedad alta → condensación | Sin sensores de humedad bajo piso técnico |
| Cableado de datos junto al de energía | Sin separación ni canalizaciones cerradas |
| Emanaciones electromagnéticas (TEMPEST) | Monitores y cables sin blindaje en área访问ible |

La clave es siempre empezar por la **vulnerabilidad** (la debilidad del activo) y después la **amenaza** (qué la aprovecha). No mezclar ambos conceptos.

---

## User

En la consigna B.2, como agrego un dispositivo USB mediante la maquina virtual (VirtualBox)? Como configuro la politica por defecto en deny?

---

## Assistant (Plan · MiMo V2.5 Free · 16.7s)

_Thinking:_

The user is asking two things:
1. How to add a USB device through VirtualBox to the VM
2. How to configure the default policy to deny in USBGuard

This is a straightforward knowledge question - I can answer directly without needing to search the codebase or make any changes. I'm in plan mode but this is just a conversational question about VirtualBox and USBGuard configuration.

**Agregar un USB en VirtualBox:**

1. Tené el pendrive conectado a tu PC física
2. En VirtualBox, con la VM apagada, andá a **Máquina → Configuración → USB**
3. Seleccioná **Controlador USB 2.0** (o 3.0 si lo soporta)
4. Hacé clic en el ícono de USB con signo + para agregar un **filtro de dispositivo** seleccionando tu pendrive de la lista
5. Prendé la VM — VirtualBox lo mapea directamente a la máquina virtual

> Si la VM ya está prendida, podés agregar el filtro y después reiniciar la VM para que lo detecte.

**Configurar USBGuard en deny por defecto:**

```bash
# Generar la política actual (los dispositivos que ya están conectados quedan permitidos)
sudo usbguard generate-policy | sudo tee /etc/usbguard/rules.conf

# Editar el archivo y cambiar la primera línea
sudo nano /etc/usbguard/rules.conf
```

Buscá la línea inicial que dice:

```
GlobalPolicy: allow
```

Cambiala a:

```
GlobalPolicy: deny
```

Reiniciá el servicio:

```bash
sudo systemctl restart usbguard
```

Ahora todo dispositivo nuevo queda **bloqueado** hasta que lo autorices explícitamente con `usbguard allow-device <n>`. Los dispositivos que estaban en la política generada quedan como reglas individuales `allow` existentes.

---

## User

No aparece la linea GlobalPolicy

---

## Assistant (Plan · MiMo V2.5 Free · 31.1s)

_Thinking:_

The user is saying that the `GlobalPolicy: deny` line doesn't appear in the USBGuard rules file. I'm in plan mode so I can only search and read - I can't make any changes. Let me check the actual content of the file to understand what format USBGuard uses in this case.

Let me search for the USBGuard configuration file to see what's actually there.

Entendido, estás en modo lectura. Déjame ver qué formato tiene el archivo generado en tu sistema.

**Tool: glob**

**Input:**
```json
{
  "pattern": "**/usbguard/**"
}
```

**Output:**
```
No files found
```

**Tool: glob**

**Input:**
```json
{
  "pattern": "**/rules.conf"
}
```

**Output:**
```
No files found
```

---

## User

no podes verlo, estoy en una VM

---

## Assistant (Plan · MiMo V2.5 Free · 5.6s)

_Thinking:_

The user is saying they can't see the file because they're in a VM. I'm in plan mode so I can only read/search. I can't access their VM's filesystem. I should just explain how to set the default deny policy without seeing the file directly.

The issue is that `usbguard generate-policy` might not include a `GlobalPolicy` line. The way to set default deny is to either:
1. Add `GlobalPolicy: deny` manually at the top of the rules file
2. Or create an empty rules file with just that line

Let me explain this to the user.

Tenés razón, no puedo acceder a tu VM. El problema es que `usbguard generate-policy` **no incluye la línea `GlobalPolicy`** por defecto — genera solo las reglas de los dispositivos conectados.

Para forzar el deny por defecto, tenés dos opciones:

**Opción A — Agregar la línea manualmente:**

```bash
echo 'GlobalPolicy: deny' | sudo tee /etc/usbguard/rules.conf
sudo usbguard generate-policy | sudo tee -a /etc/usbguard/rules.conf
sudo systemctl restart usbguard
```

**Opción B — Crear el archivo vacío con solo la política:**

```bash
sudo bash -c 'echo "GlobalPolicy: deny" > /etc/usbguard/rules.conf'
sudo usbguard generate-policy | sudo tee -a /etc/usbguard/rules.conf
sudo systemctl restart usbguard
```

La primera línea va al principio del archivo, las reglas de dispositivos conocidos se agregan después. Así todo lo nuevo queda bloqueado por defecto.

---

## User

Una vez hecho el echo "GlobalPolicy: deny" `| sudo tee /etc/usbguard/rules.conf", y teniendo el USB conectado a la maquina fisica, ahora reinicio la VM para ver que el USB no funciona?

---

## Assistant (Plan · MiMo V2.5 Free · 8.2s)

_Thinking:_

The user is asking about the workflow for testing USBGuard. They're in plan mode but this is just a conversational question about the procedure. I can answer directly.

The workflow is:
1. On the VM, set `GlobalPolicy: deny`
2. Keep the USB connected to the physical machine
3. Make sure VirtualBox is configured to pass the USB through to the VM
4. Restart the VM (or just plug in the USB after USBGuard is running)
5. Check `usbguard list-devices` — the device should show as blocked
6. Then authorize it with `usbguard allow-device <n>`

But wait — there's a subtlety. If VirtualBox filters the USB device and passes it to the VM, USBGuard inside the VM should see it. 

The key is making sure the USB device is actually being passed through to the VM by VirtualBox. I need to either add a USB filter in the VM settings or manually attach the device through the Devices menu. Once it's passed through, USBGuard will intercept it, so the restart isn't strictly necessary — I can also just unplug and replug the USB after configuring everything, or use the Devices menu to attach it on the fly.

Exacto, el flujo es:

1. **En la VM** ya configuraste `GlobalPolicy: deny` y reiniciaste USBGuard
2. **En VirtualBox** asegurate de que el USB esté pasado a la VM: **Dispositivos → USB →** seleccioná tu pendrive de la lista de la derecha
3. Conectá el pendrive a la PC física — VirtualBox lo mapea a la VM
4. **En la VM** ejecutá:
   ```bash
   usbguard list-devices`
   ```
   Debería aparecer como **blocked**

> Si no aparece, puede ser que VirtualBox no esté pasando el dispositivo. Verificá en **Máquina → Configuración → USB** que el controlador esté habilitado y que el filtro esté bien.

Una vez que lo ves bloqueado, lo autorizás con:
```bash
sudo usbguard allow-device 1
```

Y volvés a `list-devices` para ver que cambió a **allowed**. Eso es lo que tenés que capturar para el informe.

---

## User

Respondé de forma teórica la consigna B3 en tps/2/solucion

---

## Assistant (Gentle-Orchestrator · MiMo V2.5 Free · 7.6s)

_Thinking:_

The user wants me to answer B3 theoretically in the solucion.md file. B3 asks about power monitoring for a critical server with RTO of 1 hour and RPO of 15 minutes, proposing a power configuration (UPS, generator, N+1/2N redundancy) and a 3-2-1-1-0 backup strategy.

Let me first read the current solucion.md to see what's there, and also check the bibliography for relevant info about RTO, RPO, backup strategies, and power configuration.

Voy a leer la solución actual y la bibliografía para fundamentar la respuesta.

**Tool: read**

**Input:**
```json
{
  "filePath": "C:\\Users\\gonza\\arys\\tps\\2\\solucion.md"
}
```

**Output:**
```
<path>C:\Users\gonza\arys\tps\2\solucion.md</path>
<type>file</type>
<content>
1: # Trabajo Práctico 2 — Seguridad Física
2: 
3: ## Parte A — Relevamiento de un entorno
4: 
5: ### A.1 Diagrama de capas de defensa en profundidad
6: 
7: **Entorno elegido:** Se eligió mi computadora personal de escritorio.
8: 
9: [[Diagrama de capas de defensa]](assets/diagrama-defensa.png)
10: 
11: > **Capa faltante:** Las capas faltantes son la de la sala y la del rack. No tengo bajo llave la habitación ni al equipo por sí mismo. El disco no está cifrado y podrían obtenerse todos los datos si se lo roban.
12: 
13: ### A.2 Clasificación de diez controles
14: 
15: | # | Control observado | Disuasivo | Preventivo | Detectivo | Correctivo | Compensatorio |
16: |---|-------------------|:---------:|:----------:|:---------:|:----------:|:-------------:|
17: | 1 |Cámara de seguridad (desenchufada)|X|            |           |            |               |
18: | 2 |Candado de reja|           |X|           |            |               |
19: | 3 |Cerradura de puerta|           |X|            |               |
20: | 4 |Tina (Perra)||            |           |X|               |
21: | 5 |Vecino|           |            |X|            |               |
22: | 6 |Backup Google Drive|           |            |           |X|               |
23: | 7 |Gestor de contraseñas cifrado|           |X|           |            |               |
24: | 8 |Contraseña en la PC|           |X|           |            |               |
25: | 9 |Iluminación en el frente de la casa|X|            |           |            |               |
26: | 10|Sensores de movimientos (inactivos desde hace 20 años)|X|            |           |            |               |
27: 
28: ### A.3 Identificación de amenazas por familia  - A.4 Tres hallazgos de mayor riesgo
29: 
30: **Familia 1 — Acceso físico no autorizado:**
31: 
32: - **Acceso físico no autorizado**: un delincuente que fuerza la cerradura e ingresa al domicilio.
33:     - Evidencia: recurrencia de estos eventos en la ciudad de Trelew.
34: - **Desastres naturales**: inundación causada por lluvias torrenciales.
35:     - Evidencia: Antecedentes en 1998 donde el barrio fue una zona afectada. Es un área baja, cercana al Río Chubut. 
36: - **Alteraciones del entorno**: pico de tensión causando daño en el equipo.
37:     - Evidencia: En el pasado ocurrió con la PC de otro miembro de la familia.
38: 
39: ---
40: 
41: ## Parte B — Controles sobre el equipo (laboratorio)
42: 
43: ### B.1 Cifrado de disco con LUKS
44: 
45: **Código ejecutado:**
46: 
47: ```bash
48: # Crear un archivo que oficie de "disco" de laboratorio (2 GB)
49: dd if=/dev/zero of=disco_lab.img bs=1M count=2048
50: sudo losetup /dev/loop20 disco_lab.img
51: 
52: # Cifrar el dispositivo
53: sudo cryptsetup luksFormat /dev/loop20
54: 
55: # Abrirlo, formatearlo y montarlo
56: sudo cryptsetup luksOpen /dev/loop20 caja_fuerte
57: sudo mkfs.ext4 /dev/mapper/caja_fuerte
58: sudo mount /dev/mapper/caja_fuerte /mnt
59: 
60: # Inspeccionar la cabecera LUKS y los slots de clave
61: sudo cryptsetup luksDump /dev/loop20
62: ```
63: 
64: **Captura del luksDump:**
65: 
66: > [Insertar captura de pantalla aquí]
67: 
68: **Demostración de inaccesibilidad sin passphrase:**
69: 
70: ```bash
71: # Desmontar y cerrar
72: sudo umount /mnt
73: sudo cryptsetup luksClose caja_fuerte
74: 
75: # Intentar acceder al contenido sin la passphrase
76: sudo cryptsetup luksOpen /dev/loop20 caja_fuerte
77: # [Capturar resultado del intento]
78: ```
79: 
80: A continuación se ve lo que pasa cuando se ingresa una passphrase incorrecta.
81: 
82: > [No se puede acceder al archivo sin la passphrase](assets/captura-creacion-de-archivo-y-cerrado.png)
83: 
84: Además, vemos mediante un comando grep que el texto que ingresamos ("contenido sensible!!!") no se puede encontrar en el .img.
85: >[](assets/captura-contenido-no-legible.png)
86: 
87: **Respuesta:**
88: 
89: ¿Qué ataque neutraliza el cifrado de disco completo y cuál **no**?
90: 
91: - **Ataque que SÍ neutraliza:** Robo de disco con el fin de obtener información confidencial.
92: - **Ataque que NO neutraliza:** Ransomware. Los datos estarían cifrados por la clave del atacante, da igual si nosotros ya lo habíamos cifrado.
93: 
94: > **Fuente:** [Referencia a apuntes o bibliografía sobre cifrado de disco]
95: 
96: ### B.2 Bloqueo de puertos USB con USBGuard
97: 
98: **Código ejecutado:**
99: 
100: ```bash
101: sudo apt install usbguard
102: sudo usbguard generate-policy | sudo tee /etc/usbguard/rules.conf
103: sudo systemctl enable --now usbguard
104: 
105: # Ver dispositivos y su estado de autorización
106: usbguard list-devices
107: 
108: # Conectar un pendrive y autorizarlo puntualmente por su número
109: usbguard allow-device <n>
110: ```
111: 
112: **Captura de usbguard list-devices (antes de autorizar):**
113: 
114: > [Insertar captura mostrando el dispositivo bloqueado]
115: 
116: **Captura de usbguard list-devices (después de autorizar):**
117: 
118: > [Insertar captura mostrando el dispositivo autorizado]
119: 
120: Con la política por defecto en *deny*, conectá un dispositivo USB y mostrá que queda bloqueado hasta autorizarlo.
121: 
122: **Respuesta:**
123: 
124: Para probar el bloqueo del dispositivo USB, tuve que editar manualmente el archivo rules.conf con:
125: 
126: ```echo "GlobalPolicy: deny" `| sudo tee /etc/usbguard/rules.conf```
127: 
128: Y luego generando el resto del archivo con generate-policy.
129: 
130: Acto seguido, tuve que detener la MV y configurar a VirtualBox para que conecte el pendrive "Mass Storage" a la máquina virtual.
131: 
132: [](assets/config-usb-virtualbox.png)
133: 
134: Con esto, enlisté los dispositivos de la VM y vemos que el pendrive está bloqueado.
135: 
136: [](assets/pendrive-bloqueado.png)
137: 
138: 
139: *¿Por qué una lista blanca es más efectiva que una lista negra contra BadUSB / Rubber Ducky?*
140: Porque no podemos adivinar con qué dispositivo podrían atacarnos. Lo lógico es sólamente autorizar aquellos dispositivos en los que confiamos.
141: 
142: 
143: ### B.3 Monitoreo de energía
144: 
145: > **Nota:** Si no disponés de UPS con Network UPS Tools, desarrollar la respuesta teórica.
146: 
147: **Servidor crítico:**
148: - **RTO:** 1 hora
149: - **RPO:** 15 minutos
150: 
151: **Configuración de energía propuesta:**
152: 
153: | Componente | Elección | Justificación |
154: |------------|----------|---------------|
155: | UPS         | [Marca/modelo/capacidad] | [Por qué esa capacidad] |
156: | Grupo electrógeno | [Sí/No, especificación] | [Por qué se necesita o no] |
157: | Redundancia | [N+1 / 2N / otra] | [Por qué esa configuración] |
158: 
159: **Estrategia de backup 3-2-1-1-0:**
160: 
161: | Nivel | Descripción | Implementación |
162: |-------|-------------|----------------|
163: | **3** copias | [Cómo se logran] | |
164: | **2** medios | [Qué medios se usan] | |
165: | **1** fuera del sitio | [Dónde se ubica] | |
166: | **1** off-line / inmutable | [Cómo se protege] | |
167: | **0** errores | [Cómo se verifica] | |
168: 
169: **Respuesta:**
170: 
171: [Justificar cada elección en función del RTO de 1 hora y RPO de 15 minutos]
172: 
173: > **Fuente:** [Referencia a apuntes sobre disponibilidad, RTO/RPO y regla 3-2-1]
174: 
175: ---
176: 
177: ## Parte C — Plan de mejora priorizado
178: 
179: ### Tabla de tratamiento del riesgo
180: 
181: | Hallazgo | Amenaza | Impacto (A/M/B) | Probabilidad (A/M/B) | Control propuesto | Tipo de control | Cláusula ISO 27001 / Control NIST 800-53 | Prioridad |
182: |----------|---------|:----------------:|:--------------------:|-------------------|-----------------|--------------------------------------------|:---------:|
183: |          |         |                  |                      |                   |                 |                                            |           |
184: |          |         |                  |                      |                   |                 |                                            |           |
185: |          |         |                  |                      |                   |                 |                                            |           |
186: |          |         |                  |                      |                   |                 |                                            |           |
187: 
188: > **Ordenamiento:** por riesgo (impacto × probabilidad), no por costo.
189: 
190: ### Conclusión
191: 
192: **Si tuviera presupuesto para un solo control, implementaría primero:**
193: 
194: [Indicar el control elegido y justificar por qué, considerando:]
195: 
196: - Qué amenaza / hallazgo mitiga directamente
197: - Por qué tiene mejor relación costo-beneficio
198: - A qué pilar CIA protege
199: - Qué cláusula ISO 27001 o control NIST respalda la decisión
200: 
201: > **Fuente:** [Referencia a marcos normativos y apuntes]
202: 
203: ---
204: 
205: ## Para investigar (opcional)
206: 
207: ### Diferencia entre borrado, sobrescritura y desmagnetizado
208: 
209: > [Desarrollar]
210: 
211: ### Ataque cold boot y mitigación con TPM
212: 
213: > [Desarrollar]
214: 
215: ### Clonación de tarjetas de proximidad y por qué DESFire EV3 no es vulnerable
216: 
217: > [Desarrollar]

(End of file - total 217 lines)
</content>
```

---

## Assistant (Gentle-Orchestrator · MiMo V2.5 Free · 19.8s)

_Thinking:_

Now I need to fill in the B.3 section with a theoretical answer. The user has a critical server with RTO of 1 hour and RPO of 15 minutes. I need to propose a power configuration and a 3-2-1-1-0 backup strategy.

From the bibliography (unidad-02-seguridad-fisica.md):
- RTO: Recovery Time Objective — maximum tolerable downtime
- RPO: Recovery Point Objective — maximum tolerable data loss
- UPS: stabilization and short autonomy
- Generator: long autonomy
- UPS should support until generator starts or allow orderly shutdown
- Generator must be tested with load
- Redundancy: N, N+1, 2N, 2N+1


- Backup rule: 3-2-1 minimum, extended to 3-2-1-1-0 for immutable/offline copy against ransomware

Given the1-hour RTO and 15-minute RPO, I need a UPS that bridges the gap until the generator kicks in, with automatic transfer capability to keep the server online during the switchover. For the backup strategy, I'm implementing the full 3-2-1-1-0 approach with an immutable copy to protect against ransomware, ensuring I can recover within 15 minutes of data loss and get the system back up within an hour.

Perfecto, tengo todo el contexto. Voy a completar la sección B.3 con la respuesta teórica fundamentada.

**Tool: edit**

**Input:**
```json
{
  "filePath": "C:\\Users\\gonza\\arys\\tps\\2\\solucion.md",
  "oldString": "**Configuración de energía propuesta:**\n\n| Componente | Elección | Justificación |\n|------------|----------|---------------|\n| UPS         | [Marca/modelo/capacidad] | [Por qué esa capacidad] |\n| Grupo electrógeno | [Sí/No, especificación] | [Por qué se necesita o no] |\n| Redundancia | [N+1 / 2N / otra] | [Por qué esa configuración] |\n\n**Estrategia de backup 3-2-1-1-0:**\n\n| Nivel | Descripción | Implementación |\n|-------|-------------|----------------|\n| **3** copias | [Cómo se logran] | |\n| **2** medios | [Qué medios se usan] | |\n| **1** fuera del sitio | [Dónde se ubica] | |\n| **1** off-line / inmutable | [Cómo se protege] | |\n| **0** errores | [Cómo se verifica] | |\n\n**Respuesta:**\n\n[Justificar cada elección en función del RTO de 1 hora y RPO de 15 minutos]\n\n> **Fuente:** [Referencia a apuntes sobre disponibilidad, RTO/RPO y regla 3-2-1]",
  "newString": "**Configuración de energía propuesta:**\n\n| Componente | Elección | Justificación |\n|------------|----------|---------------|\n| UPS         | UPS online de doble conversión, 3 kVA, autonomía ~15 min | Estabiliza la tensión (protege contra brownout, sag y surge) y da tiempo suficiente para el apagado ordenado o el arranque del grupo. La autonomía no necesita cubrir la noche completa, solo sostener hasta que el grupo tome la carga o se apague el equipo correctamente. |\n| Grupo electrógeno | Sí, diésel de ~10 kVA con arranque automático (ATS) | Cubre la brecha que el UPS no puede: cortes de energía prolongados. El ATS (Automatic Transfer Switch) detecta la caída de red y arranca el grupo en segundos. Sin esto, un corte de más de 15 minutos violaría el RTO. |\n| Redundancia | N+1 para el UPS, 2N para la alimentación | N+1 en UPS: si un módulo falla, el otro sostiene la carga. 2N en alimentación: cada UPS tiene su propia ruta de energía (regleta distinta, breaker distinto), así no se anula la redundancia por un punto único de falla. \"Dos fuentes conectadas a la misma regleta no son redundancia\" (bibliografía §3.3). |\n\n**Estrategia de backup 3-2-1-1-0:**\n\n| Nivel | Descripción | Implementación |\n|-------|-------------|----------------|\n| **3** copias | Original + 2 réplicas | La base de datos del servidor se replica a un segundo disco interno (réplica local) y a un destino externo (réplica remota). |\n| **2** medios | Disco local + nube | La réplica local está en un disco SSD (rápido para restaurar, cumple RTO). La réplica remota está en un proveedor de almacenamiento en la nube (protege contra destrucción física del sitio). |\n| **1** fuera del sitio | Nube (proveedor cloud) | Ubicado en una región geográfica distinta. Protege contra desastres que destruyan el edificio completo (incendio, inundación). |\n| **1** off-line / inmutable | Snapshot inmutable en la nube | El proveedor de nube ofrece snapshots con lock de retención (imposible de modificar o eliminar durante el período). Protege contra ransomware que cifre los backups. |\n| **0** errores | Restauración de prueba semanal | Cada semana se restaura un backup en un entorno aislado y se verifica la integridad de los datos. \"Un backup nunca restaurado no es un backup\" (bibliografía §3.2). |\n\n**Respuesta:**\n\nLa combinación de UPS + grupo electrógeno con ATS cumple directamente con el **RTO de 1 hora**: el UPS da la estabilidad inmediata (estabilización de tensión y apagado ordenado si es necesario), y el grupo cubre cualquier corte prolongado. La redundancia N+1 en UPS y 2N en alimentación elimina puntos únicos de falla, porque si un UPS falla, el otro sostiene la carga sin interrupción.\n\nPara el **RPO de 15 minutos**, la estrategia de backup debe garantizar que la pérdida máxima de datos no supere ese umbral. Esto se logra con backups incrementales cada 15 minutos (o replicación continua) hacia el disco local, más un envío periódico a la nube. La copia local permite restauración rápida (cumpliendo RTO), la copia en nube fuera del sitio protege contra destrucción física, y el snapshot inmutable protege contra ransomware.\n\nLa prueba semanal de restauración es el eslabón crítico: sin ella, no hay garantía de que el backup funcione cuando se lo necesite.\n\n> **Fuente:** RTO/RPO y BIA: bibliografía §3.2. UPS y grupo electrógeno: bibliografía §3.3. Redundancia: \"La redundancia se expresa como N, N+1, 2N o 2N+1\" (bibliografía §3.3). Backup 3-2-1-1-0: bibliografía §3.2."
}
```

**Output:**
```
Edit applied successfully.
```

---

## Assistant (Gentle-Orchestrator · MiMo V2.5 Free · 4.8s)

_Thinking:_

The edit was applied successfully. Let me give a brief summary to the user.

Listo, completé B.3 con la respuesta teórica. Cubre:

- **UPS online de doble conversión** — estabiliza tensión y da autonomía para apagado ordenado o arranque del grupo
- **Grupo electrógeno con ATS** — cubre cortes prolongados, cumple el RTO
- **Redundancia N+1 (UPS) + 2N (alimentación)** — sin puntos únicos de falla
- **Backup 3-2-1-1-0** — cada nivel justificado en función del RTO de 1 hora y RPO de 15 minutos
- **Prueba semanal de restauración** — porque "un backup nunca restaurado no es un backup"

Todo referenciado a la bibliografía de la unidad 2.

---

## User

Resolvé la parte C con los hallazgos de la parte A.

---

## Assistant (Gentle-Orchestrator · MiMo V2.5 Free · 6.4s)

_Thinking:_

The user wants me to complete Part C of the TP2 solution, using the findings from Part A. Let me review what's in Part A to understand the findings, and then fill in the risk treatment table and conclusion.

From Part A, the three findings are:
1. Acceso físico no autorizado - delincuente que fuerza la cerradura (Alto impacto, probable en Trelew)
2. Desastres naturales - inundación por lluvias torrenciales (Alto impacto, zona baja cerca del Río Chubut, antecedentes 1998)
3. Alteraciones del entorno - pico de tensión (ya ocurrió con la PC de otro familiar)


Now I need to create the risk treatment table for Part C and write the conclusion. I'm reviewing the ISO 27001 Annex A clause 7 controls related to physical security—perimeters, entry controls, securing offices and facilities, protection against physical and environmental threats, and securing equipment—to properly map each finding to the appropriate control measures.

Voy a leer la parte A actual para asegurarme de usar los hallazgos exactos.

**Tool: read**

**Input:**
```json
{
  "filePath": "C:\\Users\\gonza\\arys\\tps\\2\\solucion.md",
  "offset": 28,
  "limit": 30
}
```

**Output:**
```
<path>C:\Users\gonza\arys\tps\2\solucion.md</path>
<type>file</type>
<content>
28: ### A.3 Identificación de amenazas por familia  - A.4 Tres hallazgos de mayor riesgo
29: 
30: **Familia 1 — Acceso físico no autorizado:**
31: 
32: - **Acceso físico no autorizado**: un delincuente que fuerza la cerradura e ingresa al domicilio.
33:     - Evidencia: recurrencia de estos eventos en la ciudad de Trelew.
34: - **Desastres naturales**: inundación causada por lluvias torrenciales.
35:     - Evidencia: Antecedentes en 1998 donde el barrio fue una zona afectada. Es un área baja, cercana al Río Chubut. 
36: - **Alteraciones del entorno**: pico de tensión causando daño en el equipo.
37:     - Evidencia: En el pasado ocurrió con la PC de otro miembro de la familia.
38: 
39: ---
40: 
41: ## Parte B — Controles sobre el equipo (laboratorio)
42: 
43: ### B.1 Cifrado de disco con LUKS
44: 
45: **Código ejecutado:**
46: 
47: ```bash
48: # Crear un archivo que oficie de "disco" de laboratorio (2 GB)
49: dd if=/dev/zero of=disco_lab.img bs=1M count=2048
50: sudo losetup /dev/loop20 disco_lab.img
51: 
52: # Cifrar el dispositivo
53: sudo cryptsetup luksFormat /dev/loop20
54: 
55: # Abrirlo, formatearlo y montarlo
56: sudo cryptsetup luksOpen /dev/loop20 caja_fuerte
57: sudo mkfs.ext4 /dev/mapper/caja_fuerte

(Showing lines 28-57 of 221. Use offset=58 to continue.)
</content>
```

---

## Assistant (Gentle-Orchestrator · MiMo V2.5 Free · 13.6s)

_Thinking:_

Good, I have the three findings from Part A. Now let me complete Part C with the risk treatment table and conclusion. The findings are:

1. Acceso físico no autorizado - delincuente que fuerza cerradura (Impacto: Alto, Probabilidad: Alta)
2. Inundación - lluvias torrenciales en zona baja (Impacto: Alto, Probabilidad: Media)
3. Pico de tensión - ya ocurrió (Impacto: Medio, Probabilidad: Media)

Now I need to propose controls for each, classify them, map to ISO 27001 clause 7 or NIST PE, and write the conclusion.

Tengo los tres hallazgos claros. Voy a completar la parte C.

**Tool: edit**

**Input:**
```json
{
  "filePath": "C:\\Users\\gonza\\arys\\tps\\2\\solucion.md",
  "oldString": "### Tabla de tratamiento del riesgo\n\n| Hallazgo | Amenaza | Impacto (A/M/B) | Probabilidad (A/M/B) | Control propuesto | Tipo de control | Cláusula ISO 27001 / Control NIST 800-53 | Prioridad |\n|----------|---------|:----------------:|:--------------------:|-------------------|-----------------|--------------------------------------------|:---------:|\n|          |         |                  |                      |                   |                 |                                            |           |\n|          |         |                  |                      |                   |                 |                                            |           |\n|          |         |                  |                      |                   |                 |                                            |           |\n|          |         |                  |                      |                   |                 |                                            |           |\n\n> **Ordenamiento:** por riesgo (impacto × probabilidad), no por costo.\n\n### Conclusión\n\n**Si tuviera presupuesto para un solo control, implementaría primero:**\n\n[Indicar el control elegido y justificar por qué, considerando:]\n\n- Qué amenaza / hallazgo mitiga directamente\n- Por qué tiene mejor relación costo-beneficio\n- A qué pilar CIA protege\n- Qué cláusula ISO 27001 o control NIST respalda la decisión\n\n> **Fuente:** [Referencia a marcos normativos y apuntes]",
  "newString": "### Tabla de tratamiento del riesgo\n\n| Hallazgo | Amenaza | Impacto (A/M/B) | Probabilidad (A/M/B) | Control propuesto | Tipo de control | Cláusula ISO 27001 / Control NIST 800-53 | Prioridad |\n|----------|---------|:----------------:|:--------------------:|-------------------|-----------------|--------------------------------------------|:---------:|\n| Acceso físico no autorizado | Delincuente que fuerza la cerradura | A | A | Cerradura eléctrica con tarjeta + cámara de seguridad operativa | Preventivo / Detectivo | ISO 27001 A.7.1 (Perímetros de seguridad), A.7.2 (Control de acceso físico) / NIST PE-2, PE-3 | 1 |\n| Inundación por lluvias torrenciales | Evento climático en zona baja, cercana al Río Chubut | A | M | Elevación del equipamiento + copia en nube fuera del sitio | Preventivo / Correctivo | ISO 27001 A.7.5 (Protección contra amenazas físicas y ambientales) / NIST PE-14, PE-17 | 2 |\n| Pico de tensión | Sobretensión de la red eléctrica | M | M | UPS online de doble conversión | Preventivo | ISO 27001 A.7.11 (Soporte de los servicios utilities) / NIST PE-14 | 3 |\n\n> **Ordenamiento:** por riesgo (impacto × probabilidad), no por costo.\n\n### Conclusión\n\n**Si tuviera presupuesto para un solo control, implementaría primero: la cerradura eléctrica con tarjeta + cámara de seguridad operativa.**\n\nEste control mitiga directamente la amenaza de mayor riesgo: el acceso físico no autorizado con impacto alto y probabilidad alta. La razón es que la demás amenaza más preocupante — la inundación — tiene probabilidad media, mientras que el acceso no autorizado es recurrente en Trelew.\n\nEn términos de costo-beneficio, una cerradura eléctrica con control por tarjeta tiene un costo moderado y reemplaza una cerradura mecánica que puede ser forzada. La cámara de seguridad, además de ser disuasiva (control disuasivo), funciona como control detectivo: registra quién ingresa y cuándo. Ambos controles trabajan juntos en defensa en profundidad.\n\nProtege el pilar de **confidencialidad** (impide el robo de información) y de **integridad** (impide la manipulación del equipo). Corresponde a la cláusula **ISO 27001 A.7.1** (Perímetros de seguridad) y **A.7.2** (Control de acceso físico), que exigen perímetros seguros y mecanismos de control de acceso para las áreas de la organización.\n\n> **Fuente:** ISO/IEC 27001:2022, Anexo A, cláusula 7 (Controles físicos) — bibliografía §4. NIST SP 800-53 Rev. 5, familia PE — bibliografía §4. Clasificación de controles: bibliografía §3.1 (tabla disuasivo/preventivo/detectivo/correctivo/compensatorio)."
}
```

**Output:**
```
Edit applied successfully.
```

---

## Assistant (Gentle-Orchestrator · MiMo V2.5 Free · 4.9s)

_Thinking:_

The edit was applied successfully. Let me give a brief summary to the user.

Listo, completé la Parte C con:

**Tabla de tratamiento del riesgo** — ordenada por riesgo (impacto × probabilidad):
1. **Acceso físico** (Alto × Alto) → cerradura eléctrica + cámara
2. **Inundación** (Alto × Medio) → elevación del equipo + copia en nube
3. **Pico de tensión** (Medio × Medio) → UPS online

**Conclusión** — justifica por qué el primer control (cerradura + cámara) es el prioritario: mitiga la amenaza de mayor riesgo, tiene mejor costo-beneficio, protege confidencialidad e integridad, y está respaldado por ISO 27001 A.7.1/A.7.2 y NIST PE-2/PE-3.

---

