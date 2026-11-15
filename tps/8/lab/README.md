# Laboratorio Docker — TP8 Monitoreo

Laboratorio reproducible que reemplaza las VMs del TP8. Todo corre en contenedores
sobre una red privada `172.28.0.0/24` y no expone servicios a la LAN: los puertos
del host se publican solo en `127.0.0.1`.

## Requisitos

- Docker Engine / Docker Desktop con Compose v2.
- Wireshark en el host para abrir las capturas (Parte A.2).
- Red en el primer build: la imagen SNMP instala `snmp-mibs-downloader` (componente
  `non-free` de Debian) para que `sysDescr.0` y `sysUpTime.0` resuelvan por nombre.

## Estructura

| Ruta | Contenido |
|------|-----------|
| `compose.yaml` | Servicios base y profiles `snmp`, `syslog`, `obs`, `obs-snmp` |
| `compose.tls.yaml` | Override opcional con `certgen` y Syslog TLS en 6514 |
| `snmp/` | Imagen del agente/manager (`snmpd`, `snmp`, `tcpdump`) |
| `syslog/` | Imagen de rsyslog (servidor UDP/TLS y cliente TLS) |
| `prometheus/` | Configuración de scrape (`self`, `node-exporter`, `snmp-exporter`) |
| `snmp-exporter/` | Módulo SNMP v2c con community `catedra` |
| `grafana/` | Datasource y dashboard auto-provisionados |
| `scripts/snmp-capture.sh` | Captura del tráfico SNMP dentro de `snmp-client` |
| `captures/` | Bind mount donde quedan los `.pcap` para Wireshark |

## Flujo rápido

```bash
# Levantar todo el laboratorio
docker compose --profile snmp --profile syslog --profile obs --profile obs-snmp up -d --build

# Bajar todo y borrar volúmenes
docker compose down -v
```

Los nombres de servicio actúan como DNS dentro de `labnet`: `snmp-agent`,
`snmp-client`, `syslog-server`, `prometheus`, `grafana`, `node-exporter`,
`snmp-exporter`.

## Parte A — SNMP

```bash
docker compose --profile snmp up -d --build

# PowerShell (host Windows)
docker compose exec snmp-client snmpwalk  -v2c -c catedra snmp-agent | Select-Object -First 20
# Bash o portable (pipe dentro del contenedor)
docker compose exec snmp-client sh -c "snmpwalk -v2c -c catedra snmp-agent | head -20"

docker compose exec snmp-client snmpget   -v2c -c catedra snmp-agent sysDescr.0
docker compose exec snmp-client snmpget   -v2c -c catedra snmp-agent sysUpTime.0
```

### A.2 Captura de la community en texto plano

La captura se hace **dentro de `snmp-client`**: en una red bridge, un contenedor
`tcpdump` aparte no ve el unicast entre otros dos contenedores. El cliente sí ve
su propio tráfico sobre `eth0`.

```bash
docker compose exec snmp-client /scripts/snmp-capture.sh
```

Eso genera `lab/captures/snmp.pcap` (visible desde Windows). Abrilo en Wireshark
y filtrá por `snmp`; la community `catedra` aparece en claro en cada mensaje v2c.

## Parte B — Syslog

```bash
docker compose --profile syslog up -d

docker compose exec syslog-client logger --server syslog-server --port 514 --udp --priority user.info "Prueba INFO desde el TP8"
docker compose exec syslog-client logger --server syslog-server --port 514 --udp --priority user.err  "Prueba ERROR desde el TP8"

docker compose exec syslog-server tail -n 20 /var/log/remote/syslog-client/*.log
```

El servidor guarda un archivo por host en `/var/log/remote/<host>/<fecha>.log`.
El puerto del host es `5514` (mapeado al 514 del contenedor) para no chocar con
un syslog local.

### B.2 Syslog centralizado con TLS (opcional)

```bash
docker compose -f compose.yaml -f compose.tls.yaml --profile syslog-tls up -d --build

docker compose exec syslog-client-tls logger -p user.info "Prueba INFO por TLS desde el TP8"
docker compose exec syslog-server-tls tail -n 20 /var/log/remote/syslog-client-tls/*.log
```

`certgen` genera una CA y un certificado de servidor con SAN
`DNS:syslog-server-tls`. El servidor escucha en `6514/tcp` con el driver
`gtls`; el cliente reenvía todos los logs cifrados.

Para bajar este perfil hay que repetir el mismo `-f`:

```bash
docker compose -f compose.yaml -f compose.tls.yaml --profile syslog-tls down -v
```

## Parte C — Observabilidad

```bash
docker compose --profile obs --profile snmp --profile obs-snmp up -d --build
```

- Prometheus: <http://localhost:9090> — consultar la métrica `up`.
- Grafana: <http://localhost:3000> — usuario `admin`, contraseña `admin`.
  El dashboard **TP8 - Observabilidad** ya está provisionado.

Jobs de scrape:

| Job | Target | Para qué |
|-----|--------|----------|
| `prometheus` | `localhost:9090` | autometría |
| `node` | `node-exporter:9100` | métricas del contenedor |
| `snmp` | `snmp-exporter:9116` → `snmp-agent` | puente SNMP → Prometheus |

`snmp-exporter` usa el módulo `lab` y la auth `lab_v2c` (community `catedra`).

## Configuración

Copiar `.env.example` a `.env` para cambiar contraseña de Grafana o puertos del
host. Valores por defecto:

| Variable | Default |
|----------|---------|
| `GRAFANA_ADMIN_PASSWORD` | `admin` |
| `HOST_PROMETHEUS_PORT` | `9090` |
| `HOST_GRAFANA_PORT` | `3000` |
| `HOST_SYSLOG_PORT` | `5514` |
| `HOST_SYSLOG_TLS_PORT` | `6514` |

## Solución de problemas

- **No aparece el `.pcap`**: verificar que el profile `snmp` esté activo y que
  `captures/` exista. El script lo crea dentro del contenedor; en Windows el bind
  mount debe apuntar a `tps/8/lab/captures`.
- **`snmpget` sin respuesta**: esperar unos segundos a que `snmpd` termine de
  arrancar; revisar `docker compose logs snmp-agent`.
- **Puerto ocupado**: cambiar el puerto del host en `.env`.
- **Grafana sin datos SNMP**: recordar levantar también `--profile snmp`; sin
  `snmp-agent` el job `snmp` queda caído (la métrica `up` lo muestra).
- **TLS no conecta**: revisar que `certgen` haya terminado
  (`docker compose ... ps`) y los logs de `syslog-server-tls`.
