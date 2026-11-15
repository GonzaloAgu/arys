# Trabajo Práctico 8 — Monitoreo

> El laboratorio se resuelve sobre Docker en `lab/` (ver `lab/README.md`). Cada
> comando `docker compose ...` reemplaza la VM que indicaba la consigna.

## Parte A — SNMP

### A.1 Consultar un agente

```bash
cd lab
docker compose --profile snmp up -d --build

# PowerShell (host Windows)
docker compose exec snmp-client snmpwalk  -v2c -c catedra snmp-agent | Select-Object -First 20
# Bash o portable (pipe dentro del contenedor)
docker compose exec snmp-client sh -c "snmpwalk -v2c -c catedra snmp-agent | head -20"

docker compose exec snmp-client snmpget   -v2c -c catedra snmp-agent sysDescr.0
docker compose exec snmp-client snmpget   -v2c -c catedra snmp-agent sysUpTime.0
```

#### Consigna A.1.1

*¿Qué información expone `snmpwalk`? Mostrá 5 OIDs y qué representan.*

[alt](./assets/captura-solucion-2026-11-15-17-23-29.png)

| OID | Nombre | Qué representa |
|----------|------------|--------------------|
| `1.3.6.1.2.1.1.1.0` | `SNMPv2-MIB::sysDescr` | Descripción textual del sistema (SO, versión y arquitectura) |
| `1.3.6.1.2.1.1.3.0` | `SNMPv2-MIB::sysUpTime` | Tiempo transcurrido desde la última inicialización del agente |
| `1.3.6.1.2.1.1.4.0` | `SNMPv2-MIB::sysContact` | Contacto administrativo del nodo |
| `1.3.6.1.2.1.1.5.0` | `SNMPv2-MIB::sysName` | Nombre administrativo del nodo |
| `1.3.6.1.2.1.1.6.0` | `SNMPv2-MIB::sysLocation` | Ubicación física del nodo |

Los OIDs y nombres corresponden al grupo `system` de `SNMPv2-MIB` [1].

#### Consigna A.1.2

*Identificá el **manager**, el **agente** y la **MIB** en lo que hiciste.*

El rol de manager lo comple el contenedor snmp-client, donde se ejecutan los comandos snmpwalk y snmpget. El agente es el contenedor snmp-agent, que corre el demonio snmpd y responde en el puerto UDP 161. El MIB es el conjunto de definiciones que describe los objetos y sus OIDs. El manager la usa para traducir los OIDs a nombres como sysDescrt e interpretar los valores.

### A.2 Por qué v2c es inseguro

```bash
docker compose exec snmp-client /scripts/snmp-capture.sh
# Abrir lab/captures/snmp.pcap en Wireshark y filtrar por "snmp"
```

#### Consigna A.2.1

*¿Pudiste **ver la community string "catedra"** en texto plano en la captura? Mostralo.*

Sí. Efectivamente se puede leer en texto plano la community string, en la solicitud get.

![captura-solucion-2026-11-15-17-53-31](assets/captura-solucion-2026-11-15-17-53-31.png)

#### Consigna A.2.2

*Explicá por qué esto es un problema grave y cómo lo resuelve **SNMP v3** (USM: autenticación + cifrado).*

 Un intruso podría estar sniffeando y obtener esta información, pudiendo acceder al agente con todos los permisos que nosotros le hayamos configurado. SNMP v3 aporta autenticación (HMAC) y cifrado mediante el User-based Security Model (USM), además de protección anti-replay. [3]
---

## Parte B — Syslog

```bash
docker compose --profile syslog up -d

docker compose exec syslog-client logger --server syslog-server --port 514 --udp --priority user.info "Prueba INFO desde el TP8"
docker compose exec syslog-client logger --server syslog-server --port 514 --udp --priority user.err  "Prueba ERROR desde el TP8"

docker compose exec syslog-server tail -n 20 /var/log/remote/syslog-client/*.log
```

```bash
# Opcional: centralización con TLS/6514
docker compose -f compose.yaml -f compose.tls.yaml --profile syslog-tls up -d --build
docker compose exec syslog-client-tls logger -p user.info "Prueba INFO por TLS desde el TP8"
docker compose exec syslog-server-tls tail -n 20 /var/log/remote/syslog-client-tls/*.log
```

#### Consigna B.1

*Ubicá tus dos mensajes y su **severidad**. Enumerá la escala 0–7.*

<!-- Respuesta + captura -->

| Nivel | Nombre | Significado |
|-------|--------|-------------|
| 0 | Emergency | |
| 1 | Alert | |
| 2 | Critical | |
| 3 | Error | |
| 4 | Warning | |
| 5 | Notice | |
| 6 | Informational | |
| 7 | Debug | |

#### Consigna B.2

*Un log solo vive en el equipo. Explicá por qué **centralizarlo** (y protegerlo con TLS/6514) es clave contra el **borrado de huellas** (Unidad 3).*

<!-- Respuesta + citas -->

---

## Parte C — Observabilidad (Prometheus + Grafana)

```bash
docker compose --profile obs --profile snmp --profile obs-snmp up -d --build

# Prometheus: http://localhost:9090  ->  consultar la métrica up
# Grafana:    http://localhost:3000  ->  admin/admin, dashboard "TP8 - Observabilidad"
```

#### Consigna C.1

*Mostrá la métrica `up` en Prometheus. ¿Qué representa?*

<!-- Respuesta + captura -->

#### Consigna C.2

*Relacioná este stack con SNMP: ¿qué rol cumple Prometheus (recolección) y cuál Grafana (visualización)?*

<!-- Respuesta -->

#### Consigna C.3

*Nombrá los **tres pilares** de la observabilidad y qué herramienta viste de cada uno.*

<!-- Respuesta -->

| Pilar | Herramienta vista |
|-------|-------------------|
| Métricas | |
| Logs | |
| Trazas | |

---

## Parte D — Cierre: del dato a la defensa

#### Consigna D.1

*De todo lo que monitoreaste (SNMP, logs, métricas), ¿qué alimentarías a un **SIEM** y para qué? Relacionalo con el **IDS** de la Unidad 5.*

<!-- Respuesta + citas -->

#### Consigna D.2

*Explicá con tus palabras cómo el monitoreo cierra el ciclo **detectar → responder → mejorar** (seguridad como proceso, Unidad 1).*

<!-- Respuesta + citas -->

---

## Referencias

<!-- Citar todas las fuentes usadas -->

1. IETF. *RFC 3418 — Management Information Base (MIB) for the Simple Network Management Protocol (SNMP)* (2002). https://www.rfc-editor.org/rfc/rfc3418
2. RFC 1157 — A Simple Network Management Protocol (SNMPv1).
3. Unidad 8 — Herramientas de Monitoreo - SNMP - Arquitectura - Las versiones y la seguridad