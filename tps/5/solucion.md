# Trabajo Práctico 5 — Firewall, IDS y Honeypot

## Parte A — Firewall con nftables

En una VM Linux (la que oficia de "servidor"):

```bash
# Ver el estado actual
sudo nft list ruleset
```
Al ejecutar este comando, observo que la VM servidor no tiene ninguna regla nft inicializada, no devuelve nada. Los comandos que ejecuté serán los que determinen la ruleset.

```bash
# Tabla y cadena de entrada con política DENY por defecto
sudo nft add table inet filtro
sudo nft add chain inet filtro entrada '{ type filter hook input priority 0; policy drop; }'
```

Con esto configuro que todos paquetes que tengan como destino a la máquina servidor, se dropeen.

```bash
# Permitir tráfico de conexiones ya establecidas (inspección de estado)
sudo nft add rule inet filtro entrada ct state established,related accept
```

Esta regla hace un *conntrack del estado* (ct state) para ver si el paquete pertenece a una conexión **establecida** o que esté **relacionada** a una conexión existente.

```bash
# Permitir loopback y SSH
sudo nft add rule inet filtro entrada iif lo accept
sudo nft add rule inet filtro entrada tcp dport 22 accept
```

La primera regla acepta los paquetes de la *input interface* (iif) de loopback.
La segunda regla permite los paquetes de entrada que tengan como destino el puerto 22 y sea TCP (es decir, SSH).


Así, finalmente el resultado de estas reglas aplicadas, con `sudo nft list ruleset` obtenemos:

```
table inet filtro {
    chain entrada {
        type filter hook input priority filter; policy drop;
        iif "lo" accept
        tcp dport 22 accept
        ct state established,related accept
    }
}
```

### Consigna 1

Con la política en `drop`, ¿qué pasa si intentás conectarte a un puerto **no** habilitado (por ejemplo, 8080) desde la otra VM? Probalo y explicá **por qué**.

La primera regla de la cadena establece la política drop, lo cual significa que si se evalúan todo el resto de reglas sin que se produzca un `accept`, entonces por defecto se descartará el paquete. Si el puerto de destino es 8080, ninguna regla lo aceptará y el paquete se descarta.

**Prueba:**
Para comprobar que se me rechaza la conexión al puerto 8080, desde una máquina kali escaneo utilizando la herramienta **netcat**

```bash
nc -vz 192.168.1.10 8080
```

Donde -v muestra información detallada y -z realiza el escaneo sin enviar datos.

Así, obtenemos como resultado una conexión rechazada

[](./assets/8080-refused.PNG)


### Consigna 2

¿Qué hace exactamente la regla `ct state established,related accept` y por qué es lo que convierte a este firewall en **stateful**? Relacionalo con la diapositiva de tipos de firewall.

Esta regla hace un análisis del estado del paquete y revisa si está *establecida* como conexión existente, o si está *relacionada* a otra conexión existente. Por analizar el estado, es que se considera un firewall **stateful**.

En la diapositiva de tipos de firewall por capa, se mencionan tres tipos: Filtrado de paquetes, inspección de estado y aplicación/proxy.
El nuestro pertenece al segundo tipo, el cual analiza la capa 3 y 4 del modelo TCP/IP (se fija tanto en las direcciones IP (capa 3) como en los puertos (capa 4)).


### Consigna 3

Explicá cómo esta configuración aplica el principio de **default deny / menor privilegio**.

Con la primera regla de la cadena, estamos estableciendo que todos los paquetes se deben rechazar salvo que haya una condición que se lo permita. Esto es un modelo de "lista blanca" y es lo más recomendado en los estándares actuales.

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
