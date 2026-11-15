FROM debian:bookworm-slim

ENV DEBIAN_FRONTEND=noninteractive

RUN sed -i 's/Components: main/Components: main non-free non-free-firmware/' \
        /etc/apt/sources.list.d/debian.sources \
    && apt-get update \
    && apt-get install -y --no-install-recommends \
        snmpd \
        snmp \
        snmp-mibs-downloader \
        tcpdump \
        procps \
        ca-certificates \
    && rm -rf /var/lib/apt/lists/*

RUN sed -i 's/^mibs :/# mibs :/' /etc/snmp/snmp.conf \
    && sed -i 's|^# mibdirs |mibdirs |' /etc/snmp/snmp.conf

RUN mkdir -p /var/lib/snmp /var/log/snmp

COPY snmpd.conf /etc/snmp/snmpd.conf

EXPOSE 161/udp

CMD ["snmpd", "-f", "-Lo", "-C", "-c", "/etc/snmp/snmpd.conf"]
