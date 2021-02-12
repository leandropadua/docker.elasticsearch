FROM ubuntu:16.04 AS builder

# install java 8 (compatible with up to 6.1.x version)
# for elasticsearch versions greater than 6.2.0, Java needs to be upgraded as well
# https://github.com/elastic/elasticsearch/pull/28071
# https://github.com/elastic/elasticsearch/blob/v6.2.0/CONTRIBUTING.md#contributing-to-the-elasticsearch-codebase
RUN DEBIAN_FRONTEND=noninteractive \
    && apt-get update && apt-get install -y \
        wget \
        unzip \
        openjdk-8-jdk \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

ENV JAVA_HOME /usr/lib/jvm/java-8-openjdk-amd64
ENV PATH $PATH:$JAVA_HOME/bin

# install gradle 3.3 as minimum specified at docs
# https://github.com/elastic/elasticsearch/blob/v6.0.0/CONTRIBUTING.md#contributing-to-the-elasticsearch-codebase
ENV GRADLE_VERSION 3.3
ENV GRADLE_ZIP_URL https://services.gradle.org/distributions/gradle-${GRADLE_VERSION}-bin.zip

RUN wget -q -O /tmp/gradle.zip ${GRADLE_ZIP_URL} \
    && unzip -q -d /opt /tmp/gradle.zip \
    && rm -f /tmp/gradle.zip

ENV GRADLE_HOME /opt/gradle-${GRADLE_VERSION}
ENV PATH $PATH:/opt/gradle-${GRADLE_VERSION}/bin

# install elasticsearch
ENV ELASTICSEARCH_VERSION 6.0.0
ENV ELASTICSEARCH_SOURCE_ZIP_URL https://github.com/elastic/elasticsearch/archive/v${ELASTICSEARCH_VERSION}.zip

# download and build with gradle
# minimum of 4GB of memory for gradle to complete the build
# otherwise a 137 error might be thrown (out of memory)
# https://github.com/gradle/gradle/issues/5102
RUN wget -q -O /tmp/elasticsearch.zip ${ELASTICSEARCH_SOURCE_ZIP_URL} \
    && unzip -q -d /usr/local/src /tmp/elasticsearch.zip\
    && rm -f /tmp/elasticsearch.zip \
    && cd /usr/local/src/elasticsearch-${ELASTICSEARCH_VERSION} \
    && gradle assemble --no-daemon --stacktrace

# multi stage build to encapsulate binaries only
# and keep the container in the minimum size possible
FROM ubuntu:16.04

# install jre only to keep the container with minimum size
RUN DEBIAN_FRONTEND=noninteractive \
    && apt-get update && apt-get install -y \
        openjdk-8-jre-headless \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

ENV JAVA_HOME /usr/lib/jvm/java-8-openjdk-amd64
ENV PATH $PATH:$JAVA_HOME/bin

COPY --from=builder /usr/local/src/elasticsearch/elasticsearch-6.0.0/distribution/tar/build/distributions/elasticsearch-6.0.0-SNAPSHOT.tar.gz /tmp/elasticsearch.tar.gz

# elasticsearch should not run as root
# create user and group named elasticsearch
RUN groupadd -g 1000 elasticsearch \
    && adduser -u 1000 -g 1000 -G 0 -d /usr/share/elasticsearch elasticsearch

RUN tar -C /tmp -xzf /tmp/elasticsearch.tar.gz \
    && mv /tmp/elasticsearch-6.0.0-SNAPSHOT/* /usr/share/elasticsearch \
    && chown -R elasticsearch:elasticsearch /usr/share/elasticsearch \
    && rm -rf /tmp/elasticsearch*

ENV PATH /usr/share/elasticsearch/bin:$PATH

WORKDIR /usr/share/elasticsearch
USER elasticsearch

# port 9200 for API calls
# port 9300 for communication between nodes
EXPOSE 9200 9300

CMD [ "elasticsearch" ]
