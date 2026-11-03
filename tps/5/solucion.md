# Trabajo Práctico 5 — Firewall, IDS y Honeypot

## Parte A — Firewall con nftables

### Consigna 1

Con la política en `drop`, ¿qué pasa si intentás conectarte a un puerto **no** habilitado (por ejemplo, 8080) desde la otra VM? Probalo y explicá **por qué**.

- Prueba: TODO
- Explicación: TODO

### Consigna 2

¿Qué hace exactamente la regla `ct state established,related accept` y por qué es lo que convierte a este firewall en **stateful**? Relacionalo con la diapositiva de tipos de firewall.

TODO

### Consigna 3

Explicá cómo esta configuración aplica el principio de **default deny / menor privilegio**.

TODO

---

## Parte B — Publicar un servicio con DNAT

### Consigna 1

Verificá desde la otra VM que accedés al servicio por el puerto 80.

TODO

### Consigna 2

**Análisis de riesgo**: cada regla DNAT "abre una puerta" desde afuera. ¿Por qué conviene que el destino de un DNAT esté en una **DMZ** y no en la LAN? (Usá el diagrama de DMZ de las filminas).

TODO

---

## Parte C — Detección con un IDS (Suricata)

### Consigna 1

Mostrá las alertas que **Suricata** generó ante el escaneo. ¿Detectó el `nmap`?

TODO

### Consigna 2

Diferencia **IDS vs IPS**: lo que hiciste, ¿frenó el escaneo o solo lo **alertó**? ¿Qué habría cambiado con Suricata en modo **IPS (inline)**?

TODO

### Consigna 3

¿La detección fue por **firmas** o por **anomalías**? Justificá.

TODO

---

## Parte D — Honeypot (Cowrie)

### Consigna 1

Mostrá qué **registró** Cowrie de tu intento: IP, usuario, contraseñas probadas, comandos.

TODO

### Consigna 2

¿Por qué se dice que un honeypot tiene **casi cero falsos positivos**? ¿Quién, legítimamente, debería estar conectándose a esa máquina?

TODO

### Consigna 3

Proponé un **honeytoken** que podrías sembrar en tu red y qué alerta dispararía.

TODO

---

## Referencias

- NIST SP 800-41 Rev. 1 — *Guidelines on Firewalls and Firewall Policy* (2009). https://csrc.nist.gov/pubs/sp/800/41/r1/final
- NIST SP 800-94 — *Guide to Intrusion Detection and Prevention Systems (IDPS)* (2007). https://csrc.nist.gov/pubs/sp/800/94/final
- RFC 2663 — *IP NAT Terminology and Considerations* (1999). https://www.rfc-editor.org/rfc/rfc2663
- RFC 3022 — *Traditional IP Network Address Translator* (2001). https://www.rfc-editor.org/rfc/rfc3022
- nftables (netfilter). https://www.netfilter.org/projects/nftables/index.html
- Suricata. https://suricata.io/
- Cowrie. https://github.com/cowrie/cowrie
