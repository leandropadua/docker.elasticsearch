FROM ubuntu:16.04 AS builder

# install java 8 (compatible with up to 6.1.x version)
# for elasticsearch versions greater than 6.2.0, Java needs to be upgraded as well
# https://github.com/elastic/elasticsearch/pull/28071
RUN DEBIAN_FRONTEND=noninteractive \
 && apt-get update && apt-get install -y \
    wget \
    unzip \
    openjdk-8-jdk \
 && rm -rf /var/lib/apt/lists/*

ENV JAVA_HOME /usr/lib/jvm/java-8-openjdk-amd64
ENV PATH $JAVA_HOME/bin:$PATH

# install gradle 3.3 as minimum specified at docs
# https://github.com/elastic/elasticsearch/blob/v6.0.0/CONTRIBUTING.md#contributing-to-the-elasticsearch-codebase
ENV GRADLE_VERSION 3.3
ENV GRADLE_ZIP_URL https://services.gradle.org/distributions/gradle-${GRADLE_VERSION}-bin.zip

RUN wget -q -O /tmp/gradle.zip ${GRADLE_ZIP_URL} \
 && unzip -q -d /opt /tmp/gradle.zip \
 && rm -f /tmp/gradle.zip

ENV GRADLE_HOME /opt/gradle-${GRADLE_VERSION}
ENV PATH /opt/gradle-${GRADLE_VERSION}/bin:$PATH

# install elasticsearch
ENV ELASTICSEARCH_VERSION 6.0.0
ENV ELASTICSEARCH_SOURCE_ZIP_URL https://github.com/elastic/elasticsearch/archive/v${ELASTICSEARCH_VERSION}.zip

# download elasticsearch source code and build with gradle
# minimum of 4GB of memory for gradle to complete the build
# otherwise a '137' error might be thrown (out of memory)
# https://github.com/gradle/gradle/issues/5102
RUN wget -q -O /tmp/elasticsearch.zip ${ELASTICSEARCH_SOURCE_ZIP_URL} \
 && unzip -q -d /usr/local/src /tmp/elasticsearch.zip\
 && rm -f /tmp/elasticsearch.zip \
 && cd /usr/local/src/elasticsearch-${ELASTICSEARCH_VERSION} \
 && gradle assemble --no-daemon --stacktrace

# unpack the generated tarball
RUN tar -C /usr/share -xzf /usr/local/src/elasticsearch-${ELASTICSEARCH_VERSION}/distribution/tar/build/distributions/elasticsearch-${ELASTICSEARCH_VERSION}-SNAPSHOT.tar.gz \
 && mv /usr/share/elasticsearch-${ELASTICSEARCH_VERSION}-SNAPSHOT /usr/share/elasticsearch \
 && rm -rf /tmp/elasticsearch.tar.gz

# multi stage build to encapsulate binaries only
# and keep the container in the minimum size possible
FROM ubuntu:16.04

# internally used to allow password bootstrap
# https://github.com/elastic/elasticsearch/commit/f275a3f07ba0cba170f17b97ffce13854242c1b3
ENV ELASTIC_CONTAINER true

# install jre only to keep the container with minimum size
RUN apt-get update && apt-get install -y \
    openjdk-8-jre-headless \
 && rm -rf /var/lib/apt/lists/*

ENV JAVA_HOME /usr/lib/jvm/java-8-openjdk-amd64
ENV PATH $JAVA_HOME/bin:$PATH

# create user and group named elasticsearch
# fix group and user id as 1000 as they need to be consistent across nodes
# https://github.com/elastic/elasticsearch/issues/11609
# set user to be part of root group (0)
# https://www.elastic.co/guide/en/cloud-enterprise/current/ece-users-permissions.html
RUN groupadd --gid 1000 elasticsearch \
 && useradd --uid 1000 --gid 1000 --groups 0 --home /usr/share/elasticsearch elasticsearch

COPY --from=builder --chown=1000:0 /usr/share/elasticsearch /usr/share/elasticsearch

# bootstrap basic config to allow single node by default
COPY --chown=1000:0 config/elasticsearch.yml /usr/share/elasticsearch/config

ENV PATH /usr/share/elasticsearch/bin:$PATH

WORKDIR /usr/share/elasticsearch
USER elasticsearch

# port 9200 for API calls
# port 9300 for communication between nodes
EXPOSE 9200 9300

CMD [ "elasticsearch" ]
