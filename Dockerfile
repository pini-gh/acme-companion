FROM docker.io/nginxproxy/docker-gen:0.10.7 AS docker-gen

FROM docker.io/library/alpine:3.19.0

ARG GIT_DESCRIBE
ARG ACMESH_VERSION=3.0.7

ENV COMPANION_VERSION=$GIT_DESCRIBE \
    DOCKER_HOST=unix:///var/run/docker.sock \
    PATH=$PATH:/app

# Install packages required by the image
RUN apk add --no-cache --virtual .bin-deps \
    bash \
    coreutils \
    curl \
    jq \
    openssl \
    socat \
    bind-tools

# Install docker-gen from the nginxproxy/docker-gen image
COPY --from=docker-gen /usr/local/bin/docker-gen /usr/local/bin/

# Install acme.sh
COPY /install_acme.sh /app/install_acme.sh
RUN chmod +rx /app/install_acme.sh \
    && sync \
    && /app/install_acme.sh \
    && rm -f /app/install_acme.sh

COPY app LICENSE /app/

WORKDIR /app

ENTRYPOINT [ "/bin/bash", "/app/entrypoint.sh" ]
CMD [ "/bin/bash", "/app/start.sh" ]
