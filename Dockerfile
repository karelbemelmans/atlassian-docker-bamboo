FROM java:openjdk-8-jre
MAINTAINER Karel Bemelmans <mail@karelbemelmans.com>

# Install git, download and extract Stash and create the required directory layout.
# Try to limit the number of RUN instructions to minimise the number of layers that will need to be created.
RUN apt-get update -qq                                                         \
    && apt-get install -y --no-install-recommends git ssh                      \
    && apt-get clean autoclean                                                 \
    && apt-get autoremove --yes                                                \
    && rm -rf /var/lib/{apt,dpkg,cache,log}/

ENV BAMBOO_VERSION 6.0.0
ENV DOWNLOAD_URL   https://downloads.atlassian.com/software/bamboo/downloads/atlassian-bamboo-
ENV BAMBOO_HOME          /var/atlassian/application-data/bamboo
ENV BAMBOO_INSTALL_DIR   /opt/atlassian/bamboo
RUN mkdir -p $BAMBOO_INSTALL_DIR

# Use the default unprivileged account. This could be considered bad practice
# on systems where multiple processes end up being executed by 'daemon' but
# here we only ever run one process anyway.
ENV RUN_USER            daemon
ENV RUN_GROUP           daemon

RUN curl -L --silent                     ${DOWNLOAD_URL}${BAMBOO_VERSION}.tar.gz | tar -xz --strip=1 -C "$BAMBOO_INSTALL_DIR" \
    && mkdir -p                          ${BAMBOO_INSTALL_DIR}/conf/Catalina      \
    && chmod -R 700                      ${BAMBOO_INSTALL_DIR}/conf/Catalina      \
    && chmod -R 700                      ${BAMBOO_INSTALL_DIR}/logs               \
    && chmod -R 700                      ${BAMBOO_INSTALL_DIR}/temp               \
    && chmod -R 700                      ${BAMBOO_INSTALL_DIR}/work               \
    && chown -R ${RUN_USER}:${RUN_GROUP} ${BAMBOO_INSTALL_DIR}/logs               \
    && chown -R ${RUN_USER}:${RUN_GROUP} ${BAMBOO_INSTALL_DIR}/temp               \
    && chown -R ${RUN_USER}:${RUN_GROUP} ${BAMBOO_INSTALL_DIR}/work               \
    && chown -R ${RUN_USER}:${RUN_GROUP} ${BAMBOO_INSTALL_DIR}/conf

# Outside the container
RUN rm /opt/atlassian/bamboo/conf/server.xml \
  && ln -s /var/atlassian/application-data/bamboo/configuration/${BAMBOO_VERSION}/conf/server.xml /opt/atlassian/bamboo/conf/server.xml

USER ${RUN_USER}:${RUN_GROUP}

VOLUME ["${BAMBOO_INSTALL_DIR}"]

# HTTP Port
EXPOSE 8085

# Remote agent port
EXPOSE 54663
EXPOSE 26224

WORKDIR $BAMBOO_INSTALL_DIR

# Run in foreground
CMD ["./bin/start-bamboo.sh", "-fg"]
