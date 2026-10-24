# Trabajo Práctico 4 — Sniffing y Análisis de tráfico

## Parte A — Armado y captura pasiva

### A.1 Laboratorio

Se mantuvo la misma MV atacante utilizada en el Laboratorio 3. Para la MV víctima, se optó por una máquina con distribución Debian. ¿El motivo? Porque es la primera distro liviana que se me ocurrió que incluye navegador.

> **Nota**: Al principio tuve problemas para que la VM de Debian actualice los paquetes apt. Era porque no estaba sincronizada la hora.

Al utilizar una red interna, tuve que configurar las IPs estáticamente con los comandos:

```
sudo ip addr add 192.168.50.10/24 dev eth0
sudo ip addr add 192.168.50.11/24 dev eth0
```

- VM-Víctima (Debian): IP 192.168.50.11, MAC 08:00:27:48:64:56
- VM-Atacante (Kali): IP 192.168.50.10, MAC 08:00:27:5a:87:bc

Verificación de conectividad (`ping`):

[](./assets/ping-entre.PNG)

### A.2 Anatomía de una conexión

Este punto fue hecho desde un WSL, ya que era mucho más práctico que hostear una web en la MV o que cambiarle la configuración de red. Y sinceramente no veo que valor le agrega hacerlo dentro de la MV.

#### Consignas A.2:

1. Localizá el handshake TCP (SYN, SYN/ACK, ACK) de la conexión. Pegá la captura.

[](./assets/handshake-tcp.png)

2. Usá Follow TCP Stream sobre el tráfico HTTP: ¿se lee la petición y la respuesta? ¿Qué datos quedarían expuestos si esto fuera un login?

Se puede ver tanto la petición en las primeras cuatro líneas, como la respuesta con las cabeceras HTTP y el HTML completo. Si esto fuera un login, podríamos leer tranquilamente las credenciales en la petición.

Resultado:
```
GET / HTTP/1.1
Host: neverssl.com
User-Agent: curl/8.5.0
Accept: */*


HTTP/1.1 200 OK
Date: Tue, 20 Oct 2026 23:19:33 GMT
Server: Apache/2.4.68 ()
Upgrade: h2,h2c
Connection: Upgrade
Last-Modified: Wed, 29 Jun 2022 00:23:33 GMT
ETag: "f79-5e28b29d38e93"
Accept-Ranges: bytes
Content-Length: 3961
Vary: Accept-Encoding
Content-Type: text/html; charset=UTF-8

<html>
	<head>
		<title>NeverSSL - Connecting ... </title>
		<style>
		body {
			font-family: Montserrat, helvetica, arial, sans-serif;
			font-size: 16x;
			color: #444444;
			margin: 0;
		}
		h2 {
			font-weight: 700;
			font-size: 1.6em;
			margin-top: 30px;
		}
		p {
			line-height: 1.6em;
		}
		.container {
			max-width: 650px;
			margin: 20px auto 20px auto;
			padding-left: 15px;
			padding-right: 15px
		}
		.header {
			background-color: #42C0FD;
			color: #FFFFFF;
			padding: 10px 0 10px 0;
			font-size: 2.2em;
		}
		.notice {
			background-color: red;
			color: white;
			padding: 10px 0 10px 0;
			font-size: 1.25em;
			animation: flash 4s infinite;
		}
		@keyframes flash {
		0% {
			background-color: red;
		}
		50% {
			background-color: #AA0000;
		}
		0% {
			background-color: red;
		}
		}
		<!-- CSS from Mark Webster https://gist.github.com/markcwebster/9bdf30655cdd5279bad13993ac87c85d -->
		</style>

		<script>
			var adjectives = [ 'cool' , 'calm' , 'relaxed', 'soothing', 'serene', 'slow',
							'beautiful', 'wonderful', 'wonderous', 'fun', 'good',
							'glowing', 'inner', 'grand', 'majestic', 'astounding',
							'fine', 'splendid', 'transcendent', 'sublime', 'whole',
							'unique', 'old', 'young', 'fresh', 'clear', 'shiny',
							'shining', 'lush', 'quiet', 'bright', 'silver' ];

			var nouns =	  [ 'day', 'dawn', 'peace', 'smile', 'love', 'zen', 'laugh',
							'yawn', 'poem', 'song', 'joke', 'verse', 'kiss', 'sunrise',
							'sunset', 'eclipse', 'moon', 'rainbow', 'rain', 'plan',
							'play', 'chart', 'birds', 'stars', 'pathway', 'secret',
							'treasure', 'melody', 'magic', 'spell', 'light', 'morning'];

			var prefix =
					// Choose 3 zen adjectives
					adjectives.sort(function(){return 0.5-Math.random()}).slice(-3).join('')
					+
					// Coupled with a zen noun
					nouns.sort(function(){return 0.5-Math.random()}).slice(-1).join('');
			window.location.href = 'http://' + prefix + '.neverssl.com/online';
		</script>
	</head>
	<body>
	<noscript>
		<div class="notice">
			<div class="container">
				...... JavaScript appears to be disabled. NeverSSL's cache-busting works better if you enable JavaScript for <code>neverssl.com</code>.
			</div>
		</div>
	</noscript>
	<div class="header">
		<div class="container">
		<h1>NeverSSL</h1>
		</div>
	</div>
	<div class="content">
	<div class="container">

	<h1 id="status"></h1>
	<script>document.querySelector("#status").textContent = "Connecting ...";</script>
	<noscript>

		<h2>What?</h2>
		<p>This website is for when you try to open Facebook, Google, Amazon, etc
		on a wifi network, and nothing happens. Type "http://neverssl.com"
		into your browser's url bar, and you'll be able to log on.</p>

		<h2>How?</h2>
		<p>neverssl.com will never use SSL (also known as TLS). No
		encryption, no strong authentication, no <a
		href="https://en.wikipedia.org/wiki/HTTP_Strict_Transport_Security">HSTS</a>,
		no HTTP/2.0, just plain old unencrypted HTTP and forever stuck in the dark
		ages of internet security.</p>

		<h2>Why?</h2>
		<p>Normally, that's a bad idea. You should always use SSL and secure
		encryption when possible. In fact, it's such a bad idea that most websites
		are now using https by default.</p>

		<p>And that's great, but it also means that if you're relying on
		poorly-behaved wifi networks, it can be hard to get online.  Secure
		browsers and websites using https make it impossible for those wifi
		networks to send you to a login or payment page. Basically, those networks
		can't tap into your connection just like attackers can't. Modern browsers
		are so good that they can remember when a website supports encryption and
		even if you type in the website name, they'll use https.</p>

		<p>And if the network never redirects you to this page, well as you can
		see, you're not missing much.</p>

        <a href="https://twitter.com/neverssl">Follow @neverssl</a>

	</noscript>

	</div>
	</div>

	</body>
</html>
```


### A.3 HTTP vs HTTPS
**Consigna A.3.** Compará ambas capturas. En la de HTTPS, ¿qué podés ver (direcciones, puerto, tamaños) y qué no podés ver (contenido)? Relacionalo con TLS 1.3 (RFC 8446).
En una conexión cifrada, el contenido del Stream es ilegible. Esto es gracias al protocolo TLS que cifra todo el contenido del payload de la capa de transporte (es decir, los datos de aplicación). Lo que no se cifra son las cabeceras de TCP, que tienen información como el tamaño en bytes, las direcciones de origen y destino, y los puertos de origen y destino.

[](assets/stream-tls.png)

#### TLS 1.3
**Nota**: El RFC 8446 es una versión obsoleta del estándar. Se toma como referencia el [RFC 9846](https://www.rfc-editor.org/info/rfc9846)
El protocolo establece un handshake inicial, donde se intercambian las llaves.

Esto se produce con el siguiente esquema de mensajes:

```
       Client                                         Server

Key  ^ ClientHello
Exch | + key_share*
     | + signature_algorithms*
     | + psk_key_exchange_modes*
     v + pre_shared_key*       -------->
                                                  ServerHello  ^ Key
                                                 + key_share*  | Exch
                                            + pre_shared_key*  v
                                        {EncryptedExtensions}  ^  Server
                                        {CertificateRequest*}  v  Params
                                               {Certificate*}  ^
                                         {CertificateVerify*}  | Auth
                                                   {Finished}  v
                               <--------  [Application Data*]
     ^ {Certificate*}
Auth | {CertificateVerify*}
     v {Finished}              -------->
       [Application Data]      <------->   [Application Data]



```

El mensaje inicial del cliente se le llama **Client Hello** y al del server **Server Hello**. En estos mensajes se define el tipo de handshake que se va a realizar (asymmetric key exchange, PSK, o combinación de ambas), las llaves que se compartirán. En base a las llaves compartidas, ambas podrán generar de forma independiente la llave simétrica (secreto compartido), con la cual establecerán comunicación cifrada.

### A.4 DNS en claro vs cifrado

**Consigna A.4.** ¿Qué revela el DNS tradicional a un sniffer aunque después uses HTTPS? Explicá cómo lo cierran DoT (RFC 7858) y DoH (RFC 8484).

Como podemos ver, la consulta anterior aunque fue cifrada, queda con sus consultas DNS visibles. Esto implica que un sniffer puede averiguar fácilmente qué sitios están visitando los usuarios de una red. Aunque no puedan ver los datos contenidos en los paquetes de la aplicación, puede ser una invasión a su privacidad.

[](./assets/dns-ws.png)

#### DoT y DoH

*DNS over TLS* implementa el mismo mecanismo descrito antes para HTTP, pero con el contenido de los mensajes DNS. Esto brinda seguridad y privacidad al usuario. *DNS over HTTS* es una alternativa donde los mensajes DNS están contenidos dentro de mensajes HTTPS. Esto hace que la solicitud DNS sea indistinguible de una solicitud web cualquiera, lo cual hace que sea aún más dificil de rastrear la actividad del usuario.

---

## Parte B — ARP spoofing / MITM controlado

> Solo entre tus dos VMs, en la red aislada. Nunca fuera de ahí.

Para esta parte, ya que las VMs están una red aislada sin gateway, tomo una propuesta de la IA de agregar un tercer nodo (clon de Debian) que ofrezca un servidor HTTP.

**IPs elegidas en las MVs**
Fueron modificadas respecto a la parte A.

| Máquina | Rol | IP |
|---|---|---|
| VM-Atacante | Kali Linux | 192.168.1.10 |
| VM-Víctima | Debian | 192.168.1.12 |
| VM-Servidor | Debian (HTTP y HTTPS) | 192.168.1.13 |

Desde el tercer nodo abrimos un servidor HTTP y HTTPS (Debian clone):
```
# HTTP en claro
sudo python3 -m http.server 80
# HTTPS con certificado autofirmado
openssl req -x509 -newkey rsa:2048 -nodes -keyout key.pem -out cert.pem -days 1 -subj "/CN=lab.local"
sudo openssl s_server -accept 443 -tls1_3 -cert cert.pem -key key.pem -www
```
 
Desde la VM-Atacante:
```
sudo bettercap -iface eth0 -eval "set arp.spoof.targets 192.168.1.12,192.168.1.13; set arp.spoof.internal true; set net.sniff.output /tmp/mitm.pcap; arp.spoof on; net.sniff on"
```

- arp.spoof.internal true: imprescindible sin gateway, spoofea hosts de la misma subred.
- Poner como targets a víctima y servidor: si solo ponés la víctima, ves únicamente el sentido víctima→servidor (la respuesta va directa por la MAC real).
- net.sniff.output te deja el .pcap para abrir en Wireshark.

### B.2 Tráfico HTTP con el MITM activo

**Consigna B.2.** Con el MITM activo, generá tráfico HTTP desde la víctima: ¿lo ve el atacante?

Con `arp.spoof` y `net.sniff` corriendo en la VM-Atacante, desde la VM-Víctima se genera una petición en claro contra el servidor del tercer nodo. Primero se agrega el nombre en `/etc/hosts` de la víctima para que la petición lleve un `Host` realista:

```bash
echo "192.168.1.13 lab.local" | sudo tee -a /etc/hosts
```

Como el tráfico pasa por Kali (que lo reenvía con `ip_forward`), bettercap muestra en consola la petición y la respuesta en claro, y el detalle completo queda en `/tmp/mitm.pcap` para abrirlo en Wireshark con **Follow TCP Stream**. Si en el directorio del `http.server` no existe `/login`, el servidor responde con un 404 (o con el listado del directorio si se pide `/`), pero eso no importa: la petición y la respuesta siguen siendo HTTP válidas y legibles.

Sí, el atacante lo ve todo: método y ruta (`GET /login?user=alumno&pass=secreto`), cabeceras `Host` y `User-Agent`, y el cuerpo de la respuesta. HTTP/1.1 se define como un protocolo de mensajes de texto y no aporta cifrado propio ([RFC 9112](https://www.rfc-editor.org/info/rfc9112)). Si la petición fuera un `POST` de login, usuario y contraseña quedarían legibles igual que en A.2.

> Lamentablemente, luego de tardes batallando y varios intentos, no pude hacer que los pcap tengan paquetes a analizar. Me rindo. Lo que si, la consola de bettercap logeaba todas las solicitudes hechas de la victima al servidor.

[](./assets/wireshark%20vacio.png)

### B.3 Tráfico HTTPS con el MITM activo

**Consigna B.3.** Generá tráfico HTTPS desde la víctima: ¿qué ve el atacante ahora? ¿Por qué el MITM no alcanza para leer el contenido?

Misma prueba, pero contra el puerto 443 del servidor.

El MITM no alcanza porque el ARP spoofing solo desvía el tráfico en capa 2: Kali queda en el medio, pero sigue siendo un intermediario pasivo que reenvía bytes. La confidencialidad la da TLS de extremo a extremo entre la víctima y el servidor. Para leer el contenido habría que **terminar** el TLS, es decir, presentarle a la víctima un certificado propio que ella acepte; eso ya no es un MITM pasivo y requeriría instalar una CA en la víctima.

### B.4 Detener el ataque

**Consigna B.4.** Detené el ataque (`arp.spoof off`) y verificá que la tabla ARP se normaliza.

En la sesión de bettercap:

```
arp.spoof off
```

Al detenerse, bettercap restaura las cachés ARP que había modificado ([documentación de `arp.spoof`](https://www.bettercap.org/modules/ethernet/spoofers/arpspoof/)). En la VM-Víctima se comprueba que la MAC de `192.168.1.13` vuelve a ser la real del servidor:

```bash
sudo ip neigh flush all
ping -c1 192.168.1.13
ip neigh
```

Se puede ver el cambio de MAC Address que la victima tiene del nodo servidor. Durante y posataque
[](./assets/ip-neigh.png)

**Entregable B:** capturas de la consola de bettercap y de Wireshark con el tráfico HTTP legible y el HTTPS cifrado, y la tabla ARP normalizada al final.

---

## Parte C — Defensas

**Consignas C:**
1. Para el ataque de la Parte B, indicá qué control de capa 2 lo hubiera frenado y cómo funciona: **Dynamic ARP Inspection** (apoyado en DHCP Snooping).

El Dynamic ARP Inspection consiste en configurar puertos de un switch como confiables y no confiables. Si se configurara el "puerto" donde "está conectada" la máquina atacante, nunca hubiera modificado su tabla ARP.

2. Para MAC flooding, ¿qué control aplica? (**Port Security**).

Se establecen límites de direcciones MAC anuncialbes por cada puerto para evitar que se desborden.

3. Explicá por qué, aun con todas las defensas de capa 2, la protección definitiva contra el sniffing es el cifrado extremo a extremo (enlazá con lo observado en A.3 y B.3).

Porque los transportes siempre pueden ser escuchados potencialemente de formas pasivas que no se pueden detectar. En esos casos, el cifrado de extremo a extremo te garantiza confidencialidad e integridad.

**Entregable C:** tabla ataque → control → cómo funciona, y el párrafo de cierre.

---

## Entrega y evaluación

- **Formato:** un único PDF con las partes A, B y C. Nombre: `TP4_ApellidoNombre.pdf`.
- **Vía:** campus virtual UNPSJB.
- **Criterios de corrección:** (ver consigna)

## Para investigar (opcional, suma)

- Qué es el SNI y cómo lo cifra ECH (RFC 9849): ¿qué metadato deja de ver el sniffer?
- JA3 / JA4: cómo se identifica un cliente o malware sin descifrar el tráfico.
- Monitor mode en Wi-Fi: por qué WPA3 (SAE) dificulta el ataque offline al handshake que sí funcionaba contra WPA2, y qué mostró Dragonblood.