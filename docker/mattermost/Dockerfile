FROM alpine:3.15

EXPOSE 8065

ENV MM_VERSION=5.26.0

RUN apk add --no-cache curl libc6-compat \
	&& rm -rf /tmp/* \
    && adduser -D -h /mattermost mattermost

USER mattermost

RUN curl https://releases.mattermost.com/$MM_VERSION/mattermost-team-$MM_VERSION-linux-amd64.tar.gz | tar -xvz \
    --exclude="mattermost/client" \
    --exclude="mattermost/prepackaged_plugins"\
    --exclude="mattermost/bin/mmctl"\
    --exclude="mattermost/bin/platform"\
    && rm -f /mattermost/config/config.json

COPY --chown=mattermost ./config.json /mattermost/config/config.json

WORKDIR /mattermost

CMD until nc -z postgres 5432; do sleep 0.5; done; /mattermost/bin/mattermost
