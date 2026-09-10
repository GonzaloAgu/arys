# Trabajo Práctico 2 — Seguridad Física

## Parte A — Relevamiento de un entorno

### A.1 Diagrama de capas de defensa en profundidad

**Entorno elegido:** Se eligió mi computadora personal de escritorio.

[[Diagrama de capas de defensa]](assets/diagrama-defensa.png)

> **Capa faltante:** Las capas faltantes son la de la sala y la del rack. No tengo bajo llave la habitación ni al equipo por sí mismo. El disco no está cifrado y podrían obtenerse todos los datos si se lo roban.

### A.2 Clasificación de diez controles

| # | Control observado | Disuasivo | Preventivo | Detectivo | Correctivo | Compensatorio |
|---|-------------------|:---------:|:----------:|:---------:|:----------:|:-------------:|
| 1 |Cámara de seguridad (desenchufada)|X|            |           |            |               |
| 2 |Candado de reja|           |X|           |            |               |
| 3 |Cerradura de puerta|           |X|            |               |
| 4 |Tina (Perra)||            |           |X|               |
| 5 |Vecino|           |            |X|            |               |
| 6 |Backup Google Drive|           |            |           |X|               |
| 7 |Gestor de contraseñas cifrado|           |X|           |            |               |
| 8 |Contraseña en la PC|           |X|           |            |               |
| 9 |Iluminación en el frente de la casa|X|            |           |            |               |
| 10|Sensores de movimientos (inactivos desde hace 20 años)|X|            |           |            |               |

### A.3 Identificación de amenazas por familia  - A.4 Tres hallazgos de mayor riesgo

**Familia 1 — Acceso físico no autorizado:**

- **Acceso físico no autorizado**: un delincuente que fuerza la cerradura e ingresa al domicilio.
    - Evidencia: recurrencia de estos eventos en la ciudad de Trelew.
- **Desastres naturales**: inundación causada por lluvias torrenciales.
    - Evidencia: Antecedentes en 1998 donde el barrio fue una zona afectada. Es un área baja, cercana al Río Chubut. 
- **Alteraciones del entorno**: pico de tensión causando daño en el equipo.
    - Evidencia: En el pasado ocurrió con la PC de otro miembro de la familia.

---

## Parte B — Controles sobre el equipo (laboratorio)

### B.1 Cifrado de disco con LUKS

**Código ejecutado:**

```bash
# Crear un archivo que oficie de "disco" de laboratorio (2 GB)
dd if=/dev/zero of=disco_lab.img bs=1M count=2048
sudo losetup /dev/loop20 disco_lab.img

# Cifrar el dispositivo
sudo cryptsetup luksFormat /dev/loop20

# Abrirlo, formatearlo y montarlo
sudo cryptsetup luksOpen /dev/loop20 caja_fuerte
sudo mkfs.ext4 /dev/mapper/caja_fuerte
sudo mount /dev/mapper/caja_fuerte /mnt

# Inspeccionar la cabecera LUKS y los slots de clave
sudo cryptsetup luksDump /dev/loop20
```

**Captura del luksDump:**

> [Insertar captura de pantalla aquí]

**Demostración de inaccesibilidad sin passphrase:**

```bash
# Desmontar y cerrar
sudo umount /mnt
sudo cryptsetup luksClose caja_fuerte

# Intentar acceder al contenido sin la passphrase
sudo cryptsetup luksOpen /dev/loop20 caja_fuerte
# [Capturar resultado del intento]
```

A continuación se ve lo que pasa cuando se ingresa una passphrase incorrecta.

> [No se puede acceder al archivo sin la passphrase](assets/captura-creacion-de-archivo-y-cerrado.png)

Además, vemos mediante un comando grep que el texto que ingresamos ("contenido sensible!!!") no se puede encontrar en el .img.
>[](assets/captura-contenido-no-legible.png)

**Respuesta:**

¿Qué ataque neutraliza el cifrado de disco completo y cuál **no**?

- **Ataque que SÍ neutraliza:** Robo de disco con el fin de obtener información confidencial.
- **Ataque que NO neutraliza:** Ransomware. Los datos estarían cifrados por la clave del atacante, da igual si nosotros ya lo habíamos cifrado.

> **Fuente:** [Referencia a apuntes o bibliografía sobre cifrado de disco]

### B.2 Bloqueo de puertos USB con USBGuard

**Código ejecutado:**

```bash
sudo apt install usbguard
sudo usbguard generate-policy | sudo tee /etc/usbguard/rules.conf
sudo systemctl enable --now usbguard

# Ver dispositivos y su estado de autorización
usbguard list-devices

# Conectar un pendrive y autorizarlo puntualmente por su número
usbguard allow-device <n>
```

**Captura de usbguard list-devices (antes de autorizar):**

> [Insertar captura mostrando el dispositivo bloqueado]

**Captura de usbguard list-devices (después de autorizar):**

> [Insertar captura mostrando el dispositivo autorizado]

Con la política por defecto en *deny*, conectá un dispositivo USB y mostrá que queda bloqueado hasta autorizarlo.

**Respuesta:**

Para probar el bloqueo del dispositivo USB, tuve que editar manualmente el archivo rules.conf con:

```echo "GlobalPolicy: deny" `| sudo tee /etc/usbguard/rules.conf```

Y luego generando el resto del archivo con generate-policy.

Acto seguido, tuve que detener la MV y configurar a VirtualBox para que conecte el pendrive "Mass Storage" a la máquina virtual.

[](assets/config-usb-virtualbox.png)

Con esto, enlisté los dispositivos de la VM y vemos que el pendrive está bloqueado.

[](assets/pendrive-bloqueado.png)


*¿Por qué una lista blanca es más efectiva que una lista negra contra BadUSB / Rubber Ducky?*
Porque no podemos adivinar con qué dispositivo podrían atacarnos. Lo lógico es sólamente autorizar aquellos dispositivos en los que confiamos.


### B.3 Monitoreo de energía

> **Nota:** Si no disponés de UPS con Network UPS Tools, desarrollar la respuesta teórica.

**Servidor crítico:**
- **RTO:** 1 hora
- **RPO:** 15 minutos

**Configuración de energía propuesta:**

| Componente | Elección | Justificación |
|------------|----------|---------------|
| UPS         | UPS online de doble conversión, 3 kVA, autonomía ~15 min | Estabiliza la tensión (protege contra brownout, sag y surge) y da tiempo suficiente para el apagado ordenado o el arranque del grupo. La autonomía no necesita cubrir la noche completa, solo sostener hasta que el grupo tome la carga o se apague el equipo correctamente. |
| Grupo electrógeno | Sí, diésel de ~10 kVA con arranque automático (ATS) | Cubre la brecha que el UPS no puede: cortes de energía prolongados. El ATS (Automatic Transfer Switch) detecta la caída de red y arranca el grupo en segundos. Sin esto, un corte de más de 15 minutos violaría el RTO. |
| Redundancia | N+1 para el UPS, 2N para la alimentación | N+1 en UPS: si un módulo falla, el otro sostiene la carga. 2N en alimentación: cada UPS tiene su propia ruta de energía (regleta distinta, breaker distinto), así no se anula la redundancia por un punto único de falla. "Dos fuentes conectadas a la misma regleta no son redundancia" (bibliografía §3.3). |

**Estrategia de backup 3-2-1-1-0:**

| Nivel | Descripción | Implementación |
|-------|-------------|----------------|
| **3** copias | Original + 2 réplicas | La base de datos del servidor se replica a un segundo disco interno (réplica local) y a un destino externo (réplica remota). |
| **2** medios | Disco local + nube | La réplica local está en un disco SSD (rápido para restaurar, cumple RTO). La réplica remota está en un proveedor de almacenamiento en la nube (protege contra destrucción física del sitio). |
| **1** fuera del sitio | Nube (proveedor cloud) | Ubicado en una región geográfica distinta. Protege contra desastres que destruyan el edificio completo (incendio, inundación). |
| **1** off-line / inmutable | Snapshot inmutable en la nube | El proveedor de nube ofrece snapshots con lock de retención (imposible de modificar o eliminar durante el período). Protege contra ransomware que cifre los backups. |
| **0** errores | Restauración de prueba semanal | Cada semana se restaura un backup en un entorno aislado y se verifica la integridad de los datos. "Un backup nunca restaurado no es un backup" (bibliografía §3.2). |

**Respuesta:**

La combinación de UPS + grupo electrógeno con ATS cumple directamente con el **RTO de 1 hora**: el UPS da la estabilidad inmediata (estabilización de tensión y apagado ordenado si es necesario), y el grupo cubre cualquier corte prolongado. La redundancia N+1 en UPS y 2N en alimentación elimina puntos únicos de falla, porque si un UPS falla, el otro sostiene la carga sin interrupción.

Para el **RPO de 15 minutos**, la estrategia de backup debe garantizar que la pérdida máxima de datos no supere ese umbral. Esto se logra con backups incrementales cada 15 minutos (o replicación continua) hacia el disco local, más un envío periódico a la nube. La copia local permite restauración rápida (cumpliendo RTO), la copia en nube fuera del sitio protege contra destrucción física, y el snapshot inmutable protege contra ransomware.

La prueba semanal de restauración es el eslabón crítico: sin ella, no hay garantía de que el backup funcione cuando se lo necesite.

> **Fuente:** RTO/RPO y BIA: bibliografía §3.2. UPS y grupo electrógeno: bibliografía §3.3. Redundancia: "La redundancia se expresa como N, N+1, 2N o 2N+1" (bibliografía §3.3). Backup 3-2-1-1-0: bibliografía §3.2.

---

## Parte C — Plan de mejora priorizado

### Tabla de tratamiento del riesgo

| Hallazgo | Amenaza | Impacto (A/M/B) | Probabilidad (A/M/B) | Control propuesto | Tipo de control | Cláusula ISO 27001 / Control NIST 800-53 | Prioridad |
|----------|---------|:----------------:|:--------------------:|-------------------|-----------------|--------------------------------------------|:---------:|
| Acceso físico no autorizado | Delincuente que fuerza la cerradura | A | A | Cerradura eléctrica con tarjeta + cámara de seguridad operativa | Preventivo / Detectivo | ISO 27001 A.7.1 (Perímetros de seguridad), A.7.2 (Control de acceso físico) / NIST PE-2, PE-3 | 1 |
| Inundación por lluvias torrenciales | Evento climático en zona baja, cercana al Río Chubut | A | M | Elevación del equipamiento + copia en nube fuera del sitio | Preventivo / Correctivo | ISO 27001 A.7.5 (Protección contra amenazas físicas y ambientales) / NIST PE-14, PE-17 | 2 |
| Pico de tensión | Sobretensión de la red eléctrica | M | M | UPS online de doble conversión | Preventivo | ISO 27001 A.7.11 (Soporte de los servicios utilities) / NIST PE-14 | 3 |

> **Ordenamiento:** por riesgo (impacto × probabilidad), no por costo.

### Conclusión

**Si tuviera presupuesto para un solo control, implementaría primero: la cerradura eléctrica con tarjeta + cámara de seguridad operativa.**

Este control mitiga directamente la amenaza de mayor riesgo: el acceso físico no autorizado con impacto alto y probabilidad alta. La razón es que la demás amenaza más preocupante — la inundación — tiene probabilidad media, mientras que el acceso no autorizado es recurrente en Trelew.

En términos de costo-beneficio, una cerradura eléctrica con control por tarjeta tiene un costo moderado y reemplaza una cerradura mecánica que puede ser forzada. La cámara de seguridad, además de ser disuasiva (control disuasivo), funciona como control detectivo: registra quién ingresa y cuándo. Ambos controles trabajan juntos en defensa en profundidad.

Protege el pilar de **confidencialidad** (impide el robo de información) y de **integridad** (impide la manipulación del equipo). Corresponde a la cláusula **ISO 27001 A.7.1** (Perímetros de seguridad) y **A.7.2** (Control de acceso físico), que exigen perímetros seguros y mecanismos de control de acceso para las áreas de la organización.

> **Fuente:** ISO/IEC 27001:2022, Anexo A, cláusula 7 (Controles físicos) — bibliografía §4. NIST SP 800-53 Rev. 5, familia PE — bibliografía §4. Clasificación de controles: bibliografía §3.1 (tabla disuasivo/preventivo/detectivo/correctivo/compensatorio).
