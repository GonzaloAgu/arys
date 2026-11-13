# Trabajo Práctico 7 — Autenticación

## Parte A — Cómo se guarda una contraseña

```bash
echo -n "Primavera2026" | sha256sum
mkpasswd -m bcrypt "Primavera2026"
mkpasswd -m bcrypt "Primavera2026"
```

### Consigna A1

*Corré `mkpasswd -m bcrypt` dos veces con la misma contraseña. ¿Por qué dan resultados distintos? (pista: la sal).*

<!-- Respuesta + captura de las dos salidas -->

### Consigna A2

*Explicá por qué un `sha256sum` no sirve para almacenar contraseñas, aunque sea un hash. Relacionalo con "el hash tiene que ser lento".*

<!-- Respuesta + referencias -->

### Consigna A3

*¿Qué agrega Argon2 sobre bcrypt? (pista: costo de memoria).*

<!-- Respuesta + referencias -->

---

## Parte B — Crackeo: débil vs. fuerte

```bash
mkpasswd -m bcrypt "123456"        > hashes.txt
mkpasswd -m bcrypt "correct horse battery staple" >> hashes.txt
john --format=bcrypt --wordlist=/usr/share/wordlists/rockyou.txt hashes.txt
john --show --format=bcrypt hashes.txt
```

### Consigna B1

*¿Cuál de las dos cayó y cuál no? ¿Por qué la longitud le gana a la complejidad? (relacionalo con la recomendación de NIST 800-63B-4).*

<!-- Respuesta + captura de salida de john -->

### Consigna B2

*¿Por qué la sal no impide el crackeo por diccionario, pero sí las rainbow tables?*

<!-- Respuesta + referencias -->

---

## Parte C — Segundo factor: TOTP

```bash
SECRET="JBSWY3DPEHPK3PXP"
oathtool --totp --base32 "$SECRET"
# Esperar más de 30 s
oathtool --totp --base32 "$SECRET"
```

### Consigna C1

*Mostrá dos códigos calculados con más de 30 s de diferencia: ¿cambió? ¿Por qué?*

<!-- Respuesta + captura de los dos códigos -->

### Consigna C2

*Si un atacante intercepta un código TOTP, ¿le sirve un minuto después? Justificá.*

<!-- Respuesta + referencias -->

### Consigna C3

*¿Qué diferencia a HOTP de TOTP en el "contador"?*

<!-- Respuesta + referencias -->

---

## Parte D — Passkeys y comparación de factores

### Registro en webauthn.io

*Entrá a la demo oficial https://webauthn.io desde tu navegador y registrá y usá una passkey (huella, PIN del dispositivo o llave). Documentá el flujo con capturas.*

<!-- Capturas del flujo de registro/uso -->

### Consigna D1

*¿En qué momento se usó tu clave privada y qué guardó el servidor? ¿Por qué una web de phishing no podría reutilizar tu passkey?*

<!-- Respuesta + referencias -->

### Consigna D2

*Completá una tabla comparando contraseña · TOTP · passkey según: ¿se puede phishear?, ¿se reutiliza?, ¿se filtra desde el servidor?*

| Factor | ¿Se puede phishear? | ¿Se reutiliza? | ¿Se filtra desde el servidor? |
|--------|---------------------|----------------|-------------------------------|
| Contraseña |  |  |  |
| TOTP |  |  |  |
| Passkey |  |  |  |

<!-- Completar y citar fuentes -->

### Consigna D3

*Explicá la diferencia entre OAuth 2.0 y OpenID Connect con el botón "iniciar sesión con Google": ¿cuál prueba quién sos?*

<!-- Respuesta + referencias -->

---

## Referencias

<!-- Numerar y completar las fuentes citadas a lo largo del informe -->
