FROM alpine:3.12

RUN apk add --no-cache synapse

RUN mkdir /media_store && \
    chown synapse:synapse /media_store && \
    mkdir /var/log/synapse/ && \
    chown synapse:synapse /var/log/synapse && \
    sed -i "s%filename: /homeserver.log%filename: /var/log/synapse/homeserver.log%" \
        /etc/synapse/my.domain.name.log.config

EXPOSE 8008

USER synapse

COPY ./homeserver.yaml ./registration.yaml /etc/synapse/

CMD until nc -z postgres 5432; do sleep 0.5; done; /usr/bin/python3 -m synapse.app.homeserver --config-path=/etc/synapse/homeserver.yaml
