#!/bin/sh
set -eu

CERTDIR="${CERTDIR:-/certs}"
mkdir -p "$CERTDIR"
cd "$CERTDIR"

cat > openssl.cnf <<'EOF'
[req]
distinguished_name = dn
x509_extensions = v3_ca
prompt = no
[dn]
CN = TP8 Lab CA
[v3_ca]
basicConstraints = critical,CA:TRUE
keyUsage = critical,keyCertSign,cRLSign
subjectKeyIdentifier = hash
EOF

openssl req -x509 -newkey rsa:2048 -sha256 -days 3650 -nodes \
    -keyout ca.key -out ca.crt -config openssl.cnf

cat > server.cnf <<'EOF'
[req]
distinguished_name = dn
req_extensions = v3_req
prompt = no
[dn]
CN = syslog-server-tls
[v3_req]
basicConstraints = CA:FALSE
keyUsage = critical,digitalSignature,keyEncipherment
extendedKeyUsage = serverAuth
subjectAltName = @alt
[alt]
DNS.1 = syslog-server-tls
DNS.2 = syslog-server
IP.1 = 127.0.0.1
EOF

openssl req -newkey rsa:2048 -sha256 -nodes \
    -keyout server.key -out server.csr -config server.cnf

openssl x509 -req -in server.csr -CA ca.crt -CAkey ca.key -CAcreateserial \
    -out server.crt -days 825 -sha256 \
    -extfile server.cnf -extensions v3_req

chmod 644 ca.crt server.crt
chmod 600 ca.key server.key
rm -f server.csr openssl.cnf server.cnf
