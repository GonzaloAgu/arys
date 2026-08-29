# Trabajo Práctico 1 — Conceptos de Seguridad

## Parte A — El inventario y la tríada

Elijo como sistema, la PC de mi trabajo, en un organismo público.

| Activo | Pilar CIA crítico | Justificación |
|--------|-------------------|---------------|
| Administración del directorio compartido | Integridad | Si se alteran los archivos puede ser grave para las operaciones del organismo. |
| Administración de licencias de Microsoft | Confidencialidad | De filtrarse, se podría hacer un uso ilegítimo de nuestras licencias Office. |
| Gestor de backups del directorio compartido (Duplicati) | Integridad | La alteración del conjunto de backups puede dejar el organismo expuesto a la pérdida de datos. |
| Sitio web y su subsistema de reclamos | Confidencialidad y Disponibilidad | Su base de datos contiene datos personales de los reclamos. Si la página se cae, se pierde el servicio a los usuarios. |
| Mi cuenta de Teams | Confidencialidad | No es importante que esté disponible ni íntegro, pero es fundamental que nadie acceda a ella, o existe el peligro de ataques mediante suplantación de identidad. |

### Mini análisis de riesgo — Activo principal

El activo más importante probablemente sea el de administración de directorios compartidos. La principal amenaza que veo es que algún tercero ingrese a mi máquina. Puede aprovecharse de la vulnerabilidad de que nuestras contraseñas son similares.

| Concepto | Valor |
|----------|-------|
| Amenaza | Acceso no autorizado de un tercero a la máquina |
| Vulnerabilidad | Contraseñas similares entre usuarios |
| Probabilidad | Bajo |
| Impacto | Alto |

> **Fuente:** Amenaza = "circunstancia o agente que pueda causar daño" (apuntes §4). Vulnerabilidad = "debilidad que la amenaza puede aprovechar" (apuntes §4). Riesgo = probabilidad × impacto (apuntes §4).

---

## Parte B — La tríada en acción

### B.1 Integridad — funciones de hash

Se creó un archivo `orden.txt` con el contenido original y se calculó su hash SHA-256. Luego se alteró un solo carácter (1000 → 9000) y se volvió a calcular.

**Código ejecutado:**

```bash
echo "Transferir 1000 a la cuenta 55" > orden.txt
Get-FileHash -Algorithm SHA256 orden.txt

echo "Transferir 9000 a la cuenta 55" > orden.txt
Get-FileHash -Algorithm SHA256 orden.txt
```

**Comparación de hashes:**

| Versión | Contenido | SHA-256 |
|---------|-----------|---------|
| Original | Transferir 1000 a la cuenta 55 | `6068A4CC2E99372A1C21D015AC93CEC8D9993C22465CC7B68E3CD5D0C821B7E6` |
| Alterado | Transferir 9000 a la cuenta 55 | `95180D1A89125162D1B438C5725E49EB9906D28F7F677FD37D4970575C05E805` |

**Respuesta:**

Al cambiar un solo dígito (1000 → 9000), el hash SHA-256 cambió completamente. La integridad se protege con funciones de hash porque permiten detectar si la información fue alterada: si alguien modifica el archivo, el hash calculado no coincidirá con el original. Sin embargo, el hash no sirve para deshacer la alteración porque es una función unidireccional — solo permite saber *si* el archivo fue modificado, pero no *qué* cambió ni cómo restaurarlo.

> **Fuente:** "La información no debe alterarse de forma no autorizada, y una modificación debe poder detectarse. Se protege con funciones de hash, firmas digitales, control de versiones y permisos." (apuntes §2.2).

### B.2 Confidencialidad — cifrado simétrico

Se cifró el archivo `orden.txt` con GnuPG usando cifrado simétrico (contraseña). Luego se intentó leer el archivo cifrado sin la clave, y finalmente se descifró con la contraseña correcta.

**Código ejecutado:**

```bash
gpg -c orden.txt          # genera orden.txt.gpg
cat orden.txt.gpg         # basura binaria
gpg -d orden.txt.gpg      # se recupera con la contraseña
```

**Respuesta:**

El cifrado simétrico protege la confidencialidad: el archivo cifrado (`orden.txt.gpg`) es ilegible sin la contraseña. Si alguien roba el archivo cifrado pero no la contraseña, no se violó la confidencialidad, porque el contenido permanece protegido. Sin embargo, si además borra tu única copia, se viola la disponibilidad: ya no podés recuperar el archivo ni con la contraseña. Esto muestra por qué es importante mantener backups de los archivos cifrados.

> **Fuente:** "La información debe ser accesible únicamente para quien está autorizado. Se protege principalmente con cifrado, control de acceso y clasificación de la información." (apuntes §2.1). Disponibilidad: "Se vulnera cuando algo no está (un servidor caído, un backup que nunca se probó)." (apuntes §2.3).

### B.3 Confidencialidad e integridad — control de acceso

Se inspeccionaron los permisos actuales del archivo `orden.txt` y luego se restringieron para que solo el dueño pueda leer y escribir.

**Código ejecutado:**

```bash
ls -l orden.txt
chmod 600 orden.txt
ls -l orden.txt           # -rw-------
```

**Respuesta:**

El valor `600` en `chmod` significa: dueño = lectura (4) + escritura (2) = 6; grupo = nada (0); otros = nada (0). Solo el usuario propietario puede leer y modificar el archivo.

Esto aporta a la confidencialidad porque impide que otros usuarios lean el contenido, y aporta a la integridad porque impide que otros lo modifiquen sin autorización. Se relaciona con el principio de **menor privilegio**: cada usuario recibe solo los permisos que necesita, minimizando la superficie de ataque.

> **Fuente:** Elementos del control de acceso: "Autorización: son los permisos asociados al usuario autenticado" (apuntes §Amenazas en el control de acceso). Menor privilegio: "cada usuario o proceso recibe solo los permisos que necesita. Es, probablemente, el principio más rentable" (apuntes §6).

### B.4 Disponibilidad — el backup que se prueba

Se simuló la pérdida del archivo original y su restauración desde un backup.

**Código ejecutado:**

```bash
cp orden.txt orden.bak
rm orden.txt              # "perdimos" el original
cp orden.bak orden.txt    # restauramos
cat orden.txt
```

**Respuesta:**

El backup protege el pilar de **disponibilidad**: garantiza que la información esté accesible cuando se la necesita, incluso ante la pérdida del original. Sin embargo, un backup que nunca se restauró no cuenta como control efectivo, porque no hay garantía de que funcione cuando se lo necesite. Podría estar corrupto, incompleto o desactualizado.

La regla **3-2-1** (que veremos en la Unidad 2) establece: mantener **3** copias de los datos, en **2** medios diferentes, con **1** copia fuera del sitio. Esto asegura que si un evento destruye una copia (incendio, robo, fallo de disco), siempre exista al menos una alternativa accesible y funcional.

> **Fuente:** "Se vulnera cuando algo no está (un servidor caído, un ataque de denegación de servicio, un backup que nunca se probó). Se protege con redundancia, backups, balanceo de carga y mantenimiento." (apuntes §2.3 – Disponibilidad).
