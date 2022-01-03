FROM alpine:3.15

EXPOSE 22

RUN apk add --no-cache openssh-server && \
    ssh-keygen -A && \
    adduser -D proxy && \
    passwd -d proxy

COPY ./sshd_config /etc/ssh/sshd_config
CMD ["/usr/sbin/sshd", "-De"]
