#!/bin/sh
set -eu

CAPTURE="${CAPTURE:-/captures/snmp.pcap}"
TARGET="${TARGET:-snmp-agent}"
COMMUNITY="${COMMUNITY:-catedra}"

rm -f "$CAPTURE"

timeout 15 tcpdump -i eth0 -w "$CAPTURE" -c 2 udp port 161 &
PID=$!

sleep 1
snmpget -v2c -c "$COMMUNITY" "$TARGET" sysDescr.0
wait "$PID" || true

ls -l "$CAPTURE"
