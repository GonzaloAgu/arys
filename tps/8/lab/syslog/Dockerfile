FROM debian:bookworm-slim

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        rsyslog \
        rsyslog-gnutls \
        util-linux \
        procps \
        ca-certificates \
    && rm -rf /var/lib/apt/lists/*

RUN mkdir -p /var/log/remote /etc/rsyslog-certs

EXPOSE 514/udp
EXPOSE 6514

CMD ["rsyslogd", "-n"]
