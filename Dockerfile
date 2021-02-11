FROM ubuntu:16.04 AS builder

# install java and ubuntu packages
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

RUN wget -q -O /tmp/elasticsearch.zip ${ELASTICSEARCH_SOURCE_ZIP_URL} \
    && unzip -q -d /usr/local/src/elasticsearch /tmp/elasticsearch.zip\
    && rm -f /tmp/elasticsearch.zip \
    && cd /usr/local/src/elasticsearch/elasticsearch-${ELASTICSEARCH_VERSION}

RUN cd /usr/local/src/elasticsearch/elasticsearch-${ELASTICSEARCH_VERSION} \
    && gradle assemble --stacktrace

FROM ubuntu:16.04

RUN DEBIAN_FRONTEND=noninteractive \
    && apt-get update && apt-get install -y \
        openjdk-8-jre-headless \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

ENV JAVA_HOME /usr/lib/jvm/java-8-openjdk-amd64
ENV PATH $PATH:$JAVA_HOME/bin

COPY --from=builder /usr/local/src/elasticsearch/elasticsearch-6.0.0/distribution/tar/build/distributions/elasticsearch-6.0.0-SNAPSHOT.tar.gz /tmp/elasticsearch.tar.gz

RUN groupadd --gid 1000 elasticsearch && useradd -u 1000 -g 1000 -m elasticsearch

RUN tar -C /usr/share/ -xzf /tmp/elasticsearch.tar.gz \
    && mv /usr/share/elasticsearch-6.0.0-SNAPSHOT /usr/share/elasticsearch \
    && chown -R elasticsearch:elasticsearch /usr/share/elasticsearch \
    && rm -f /tmp/elasticsearch.tar.gz

ENV PATH /usr/share/elasticsearch/bin:$PATH

USER elasticsearch
EXPOSE 9200 9300

CMD [ "/usr/share/elasticsearch/bin/elasticsearch" ]
