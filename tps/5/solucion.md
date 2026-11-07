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

```bash
python3 -m http.server 8000 &     # servicio interno en el puerto 8000

# DNAT: redirigir el puerto público 80 al servicio interno 8000
sudo nft add chain inet filtro prerouting '{ type nat hook prerouting priority -100; }'
sudo nft add rule inet filtro prerouting tcp dport 80 dnat ip to :8000
```

>**Nota**: el comando `sudo nft add rule inet filtro prerouting tcp dport 80 dnat ip to :8000` no me funcionó, me dice que es incorrecta la sintaxis de los dos puntos antes del 8000. Tuve que cambiarlo por `sudo nft add rule inet filtro prerouting tcp dport 80 redirect to :8000`

Con esa salvedad, vemos que el kali accede correctamente al servicio HTTP.

[](./assets/kali-accede-http.PNG)

### Consigna 2
**Análisis de riesgo**: cada regla DNAT "abre una puerta" desde afuera. ¿Por qué conviene que el destino de un DNAT esté en una **DMZ** y no en la LAN? (Usá el diagrama de DMZ de las filminas).

Lo que se encuentra en un destino de DNAT generalmente va a ser un servicio público, accesible por gente que no es de confianza. Estos servicios deberían correr en una zona desmilitarizada, desde la cual no tengan acceso a la red local de la organización. Uno nunca sabe cuando puede encontrarse una vulnerabilidad en un servicio web que le permita escapar hacia otros servicios internos y delicados.

---

## Parte C — Detección con un IDS (Suricata)
En la VM "servidor", instalá y ejecutá **Suricata** en modo IDS sobre la interfaz de laboratorio:

```bash
sudo suricata -i enp0s3 &        # análisis en vivo, en la interfaz correspondiente a mi VM
```

Desde la VM "atacante", repetí un escaneo de la Unidad 3

```bash
sudo nmap -sS -sV 192.168.1.11
```

### Consigna 1
Mostrá las alertas que **Suricata** generó ante el escaneo. ¿Detectó el `nmap`?

Suricata no mostró ningún alerta. No registró nada. El escaneo desde la kali fue exitoso (mostrando los puertos http abiertos anteriormente), sin dejar ningún rastro.
 
Esto aparentemente se debe a que Suricata no trae incluido un conjunto de reglas de protección,y se requiere ejecutar `sudo suricata-update`.

Hice el cambio temporal de host-only a NAT en la configuración de red de la VM, ejecuté dicho comando y lo intenté nuevamente. Además, tuve que configurar en /etc/suricata/suricata.yaml el `HOME_NET` para que toda la red se considere insegura, ya que de lo contrario se estaban salteando las alertas de la red privada.

Aún así, Suricata no mostró nada del escaneo.

### Consigna 2
Diferencia **IDS vs IPS**: lo que hiciste, ¿frenó el escaneo o solo lo **alertó**? ¿Qué habría cambiado con Suricata en modo **IPS (inline)**?

Suponiendo que hubiera alertado, lo que se hizo fue un IDS (Intruder Detection System). Sólo se alertó. En el modo IPS, Suricata tiene la capacidad de filtrar/descartar los paquetes que le parezcan sospechosos según su conjunto de reglas configurado.

### Consigna 3
¿La detección fue por **firmas** o por **anomalías**? Justificá.

No se puede responder ya que no hubo detección. Sin embargo, Suricata suele basarse principalmente en la detección por firmas, añadiendo algunos elementos de detección por anomalías. Es decir, se basa más en la inspección de los paquetes para detectar patrones de ataque conocidos, más que en el comportamiento de quien los envía.

---

## Parte D — Honeypot (Cowrie)

### Consigna 1
Mostrá qué **registró** Cowrie de tu intento: IP, usuario, contraseñas probadas, comandos.

Al intentar conectarme desde kali, quedó el fingerprint del curioso.

[](./assets/cowrie-logs.PNG)

### Consigna 2
¿Por qué se dice que un honeypot tiene **casi cero falsos positivos**? ¿Quién, legítimamente, debería estar conectándose a esa máquina?

Los honeypots están predefinidas como máquinas que no tienen un propósito real para ninguno de los miembros de una organización. El que intente conectarse con ella, se puede asumir como un hacker no ético potencialmente peligroso, cuya IP debería bloquearse de inmediato.

### Consigna 3
Proponé un **honeytoken** que podrías sembrar en tu red y qué alerta dispararía.

Un posible honeytoken puede ser un sitio HTTP simple cuya página principal ejecute un script que envíe un mensaje a los administradores IT de la organización, indicando su origen y bloqueando la IP automáticamente.

---

## Referencias

- NIST SP 800-41 Rev. 1 — *Guidelines on Firewalls and Firewall Policy* (2009). https://csrc.nist.gov/pubs/sp/800/41/r1/final
- NIST SP 800-94 — *Guide to Intrusion Detection and Prevention Systems (IDPS)* (2007). https://csrc.nist.gov/pubs/sp/800/94/final
- RFC 2663 — *IP NAT Terminology and Considerations* (1999). https://www.rfc-editor.org/rfc/rfc2663
- RFC 3022 — *Traditional IP Network Address Translator* (2001). https://www.rfc-editor.org/rfc/rfc3022
- nftables (netfilter). https://www.netfilter.org/projects/nftables/index.html
- Suricata. https://suricata.io/
- Cowrie. https://github.com/cowrie/cowrie
