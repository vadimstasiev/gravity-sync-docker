FROM            alpine:latest as baseenvironment

LABEL           maintainer Michael Thompson <mike@michael-thompson.net>

ENV             GS_INSTALL="secondary" \
                GS_VERSION="3.2.6" \
                GENERATE_SSH_CERTS="true" \
                TINI_VERSION="0.19.0" \
                DEBUG="false" \
                SYNC_FREQUENCY="30" \
                BACKUP_HOUR="1" \
                REMOTE_HOST="127.0.0.1" \
                SSH_PORT="22" \
                REMOTE_USER="root" \
                LOCAL_HOST_TYPE="docker" \
                REMOTE_HOST_TYPE="docker" \
                LOCAL_PIHOLE_DIR="/etc/pihole/" \
                REMOTE_PIHOLE_DIR="/etc/pihole/" \
                LOCAL_PIHOLE_BIN="" \
                REMOTE_PIHOLE_BIN="" \
                LOCAL_DOCKER_BIN="" \
                REMOTE_DOCKER_BIN="" \
                LOCAL_FILE_OWNER="root:root" \
                REMOTE_FILE_OWNER="root:root" \
                LOCAL_DOCKER_CON="" \
                REMOTE_DOCKER_CON="" \
                GRAVITY_FI="" \
                CUSTOM_DNS="" \
                VERIFY_PASS="" \
                SKIP_CUSTOM="" \
                DATE_OUTPUT="" \
                PING_AVOID="" \
                ROOT_CHECK_AVOID="" \
                BACKUP_RETAIN="" \
                SSH_PKIF=""

ADD             https://github.com/krallin/tini/releases/download/v${TINI_VERSION}/tini-static /tini

RUN             chmod +x /tini && \
                apk --update add openssh sudo bash coreutils && \
                apk add util-linux


FROM            baseenvironment as buildenvironment

                # apk --update add less rsync sqlite
RUN             apk --update add curl && \
                rm -rf /var/lib/apt/lists/* && \
                rm /var/cache/apk/* && \
                cd /tmp/ && \
                wget https://github.com/vmstan/gravity-sync/archive/v$GS_VERSION.zip && \
                mkdir /tmp/gravity-sync/ && \
                unzip v$GS_VERSION.zip -d /tmp/gravity-sync/ && \
                mv /tmp/gravity-sync/gravity-sync-$GS_VERSION /root/gravity-sync


FROM            baseenvironment as prodbuildenvironment

COPY            configure.sh /usr/local/bin/configure.sh
COPY            prelaunch.sh /usr/local/bin/prelaunch.sh
COPY            startup.sh /usr/local/bin/startup.sh
COPY            --from=buildenvironment /root/gravity-sync/ /root/gravity-sync/

WORKDIR         /root/gravity-sync/

RUN             apk --update add rsync sqlite docker-cli && \
                rm -rf /var/lib/apt/lists/* && \
                rm /var/cache/apk/* && \
                echo 'echo "Git is not required"' > /usr/local/bin/git && \
                chmod +x /usr/local/bin/git && \
                chmod +x /usr/local/bin/configure.sh && \
                chmod +x /usr/local/bin/prelaunch.sh && \
                chmod +x /usr/local/bin/startup.sh && \
                sed -i 's/smart/push/g' /root/gravity-sync/includes/gs-automate.sh;

ENTRYPOINT      ["/tini", "--"]
CMD             ["/usr/local/bin/startup.sh"]
