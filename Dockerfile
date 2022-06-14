FROM ubuntu:bionic

ENV MALLOC_ARENA_MAX=1
ENV TZ=UTC
ENV DEBIAN_FRONTEND=noninteractive
ENV GP_DB=test
ENV GP_USER=postgres
ENV GP_PASSWORD=postgres
ENV GP_VERSION=6.21.0
ENV GPHOME=/usr/local/greenplum-db-${GP_VERSION}

RUN apt-get update -y &&\
    apt-get install -y sudo apt-utils software-properties-common curl locales &&\
    apt-get update -y &&\
    apt-get dist-upgrade -y &&\
    locale-gen en_US.UTF-8 &&\
    curl -SL -o greenplum-db.deb https://github.com/greenplum-db/gpdb/releases/download/${GP_VERSION}/greenplum-db-${GP_VERSION}-ubuntu18.04-amd64.deb &&\
    apt-get install -y ./greenplum-db.deb &&\
    rm greenplum-db.deb &&\
    rm -rf /var/lib/apt/lists/* &&\
    rm -rf /tmp/*  &&\
    groupadd -g 4321 gpdb &&\
    useradd -g 4321 -u 4321 --shell /bin/bash -m -d /home/gpdb gpdb &&\
    echo "gpdb:pivotal"|chpasswd &&\
    echo "gpdb        ALL=(ALL)       NOPASSWD: ALL" >> /etc/sudoers  &&\
    mkdir -p /srv/gpmaster  &&\
    mkdir -p /srv/gpdata && \
    chown -R gpdb:gpdb /home/gpdb &&\
    chown -R gpdb:gpdb /srv

COPY entrypoint.sh ./entrypoint.sh
RUN chmod +x ./entrypoint.sh

ENTRYPOINT ["/bin/bash", "entrypoint.sh"]
