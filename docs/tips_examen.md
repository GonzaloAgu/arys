Buen día, chicos. Emiliano me pregunta qué es lo más importante para estudiar para el parcial del viernes, y si las normas y estándares se piden de memoria. Lo aclaro para todos.

Contenidos: unidades 5, 6 y 7 (Firewall, IDS y Honeypot; Criptografía; Sistemas de Autenticación).

Normas y estándares: no se estudian de memoria. No les voy a pedir números de normas, RFC ni años. Alcanza con saber para qué se usa cada una de las principales.

Lo importante:
- Firewall: qué es, qué tipos hay, cómo se configuran y dónde se ubican en la red. IDS, IPS y honeypots.
- Criptografía: cifrado simétrico y asimétrico, hash, firma digital y certificados.
- Autenticación: factores y MFA, cómo se guardan las contraseñas, Kerberos, TOTP y OAuth.

En todos los casos, entender los conceptos y repasar lo que se hizo en la práctica. El parcial es de opción múltiple y apunta a aplicar los conceptos a casos, no a repetir definiciones.

Ejemplo de pregunta (es lo que tendrían que haber practicado):

Un administrador quiere bloquear el acceso SSH desde la red 203.0.113.0/24 y carga este conjunto de reglas en el servidor:


table inet filtro {
  chain entrada {
    type filter hook input priority 0; policy drop;
    ct state established,related accept
    tcp dport 22 accept
    ip saddr 203.0.113.0/24 tcp dport 22 drop
    tcp dport { 80, 443 } accept
  }
}


Desde 203.0.113.50 se intenta abrir una conexión SSH nueva al servidor. ¿Qué ocurre?

a) Se descarta, porque la regla más específica tiene prioridad sobre la más general.
b) Se acepta, porque coincide primero con "tcp dport 22 accept" y la regla de bloqueo nunca se evalúa.
c) Se descarta, porque la política drop de la cadena se aplica antes que las reglas.
d) Se acepta solo si ya existía una conexión establecida desde esa dirección.

Piénsenla y después les paso la respuesta.

Una aclaración sobre nftables, porque el ejemplo de pregunta que les pasé se ve distinto a lo que hicieron en la práctica.

En la práctica ustedes hicieron esto: cargaron las reglas con comandos, de a una.


sudo nft add table inet filtro
sudo nft add chain inet filtro entrada '{ type filter hook input priority 0; policy drop; }'
sudo nft add rule inet filtro entrada ct state established,related accept
sudo nft add rule inet filtro entrada iif lo accept
sudo nft add rule inet filtro entrada tcp dport 22 accept


Pero también podían hacer esto: escribir todo en un archivo y cargarlo de una vez con "sudo nft -f archivo".


table inet filtro {
  chain entrada {
    type filter hook input priority 0; policy drop;
    ct state established,related accept
    iif "lo" accept
    tcp dport 22 accept
  }
}


Las dos formas dejan el firewall exactamente igual. De hecho, la segunda es lo que ven cuando ejecutan "sudo nft list ruleset".

Diferencias a tener en cuenta:
- Con comandos, cada regla se aplica al instante y "add rule" la agrega al final de la cadena.
- Con el archivo, se carga todo junto o no se carga nada, y el orden de las reglas es el que se lee.
- Ninguna de las dos sobrevive al reinicio por sí sola. Para eso se guarda el archivo en /etc/nftables.conf, que es el que carga el servicio nftables al arrancar.

En el parcial las configuraciones aparecen en el formato de archivo, así que practiquen leerlas así: de arriba hacia abajo, y la política se aplica solo si ninguna regla coincide.