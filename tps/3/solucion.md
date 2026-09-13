# Trabajo Práctico 3 - Reconocimiento y escaneo

## Parte A — Armado del laboratorio

Se logró instalar ambas máquinas virtuales sobre el mismo dispositivo utilizando VirtualBox. Se las configuró con **una red interna en común**, sin que estén conectadas a internet.

![](assets/config-red-interna.PNG)

Se guardó una snapshot inicial de la VM que será atacada.

### Asignación de IPs
Al conectar las máquinas virtuales a la red interna, se les asignó sólo una IPv6 a cada una, con un sufijo de red /64 (64 bits asignados a la subred).

Esto sirve para nuestros fines, y se puede comprobar que las IPs pertenecen a la misma subred.

|IP Kali|IP Metasploitable|
|-|-|
|fd17:625c:f037:2:130d:7b21:e66d:4b3a/64|fd17:625c:f037:2:a00:27ff:fe5c:a490/64|

![](assets/ips-de-vms.PNG)

Además, a continuación se comprueba que las máquinas pueden comunicarse entre sí, realizando un ping desde Kali.

![](assets/ping-kali-a-metasploitable.PNG)