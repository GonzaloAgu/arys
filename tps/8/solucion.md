# Trabajo Práctico 8 — Monitoreo

## Parte A — SNMP

### A.1 Consultar un agente

```bash
sudo apt install snmpd snmp
echo 'rocommunity catedra' | sudo tee -a /etc/snmp/snmpd.conf
sudo systemctl restart snmpd

snmpwalk  -v2c -c catedra localhost | head -20
snmpget   -v2c -c catedra localhost sysDescr.0
snmpget   -v2c -c catedra localhost sysUpTime.0
```

#### Consigna A.1.1

*¿Qué información expone `snmpwalk`? Mostrá 5 OIDs y qué representan.*

<!-- Respuesta + captura -->

| OID | Nombre | Qué representa |
|-----|--------|----------------|
|     |        |                |
|     |        |                |
|     |        |                |
|     |        |                |
|     |        |                |

#### Consigna A.1.2

*Identificá el **manager**, el **agente** y la **MIB** en lo que hiciste.*

<!-- Respuesta -->

### A.2 Por qué v2c es inseguro

```bash
sudo tcpdump -i lo -w snmp.pcap udp port 161 &
snmpget -v2c -c catedra localhost sysDescr.0
# Abrir snmp.pcap en Wireshark
```

#### Consigna A.2.1

*¿Pudiste **ver la community string "catedra"** en texto plano en la captura? Mostralo.*

<!-- Respuesta + captura de Wireshark -->

#### Consigna A.2.2

*Explicá por qué esto es un problema grave y cómo lo resuelve **SNMP v3** (USM: autenticación + cifrado).*

<!-- Respuesta + citas -->

---

## Parte B — Syslog

```bash
logger -p user.info  "Prueba INFO desde el TP8"
logger -p user.err   "Prueba ERROR desde el TP8"

sudo tail -n 20 /var/log/syslog
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
docker run -d --name prometheus -p 9090:9090 prom/prometheus
docker run -d --name grafana -p 3000:3000 grafana/grafana
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

1. 
2. 
