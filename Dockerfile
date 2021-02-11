FROM ubuntu:16.04

# install java and ubuntu packages
RUN DEBIAN_FRONTEND=noninteractive \
    && apt-get update && apt-get install -y \
        wget \
        unzip \
        openjdk-8-jdk \
    && rm -rf /var/lib/apt/lists/*

ENV JAVA_HOME /usr/lib/jvm/java-8-openjdk-amd64
ENV PATH $PATH:$JAVA_HOME/bin

# FROM openjdk:8

# install gradle 3.3 as minimum specified at docs
# https://github.com/elastic/elasticsearch/blob/v6.0.0/CONTRIBUTING.md#contributing-to-the-elasticsearch-codebase
ENV GRADLE_VERSION 3.3
ENV GRADLE_ZIP_URL https://services.gradle.org/distributions/gradle-${GRADLE_VERSION}-bin.zip

RUN wget -q -O /tmp/gradle.zip ${GRADLE_ZIP_URL} \
    && unzip -d /opt /tmp/gradle.zip \
    && rm -f /tmp/gradle.zip

ENV GRADLE_HOME /opt/gradle-${GRADLE_VERSION}
ENV PATH $PATH:/opt/gradle-${GRADLE_VERSION}/bin

# install elasticsearch
ENV ELASTICSEARCH_VERSION 6.0.0
ENV ELASTICSEARCH_SOURCE_ZIP_URL https://github.com/elastic/elasticsearch/archive/v${ELASTICSEARCH_VERSION}.zip

RUN wget -q -O /tmp/elasticsearch.zip ${ELASTICSEARCH_SOURCE_ZIP_URL} \
    && unzip -d /usr/local/src/elasticsearch /tmp/elasticsearch.zip\
    && rm -f /tmp/elasticsearch.zip \
    && cd /usr/local/src/elasticsearch/elasticsearch-${ELASTICSEARCH_VERSION}

RUN cd /usr/local/src/elasticsearch/elasticsearch-${ELASTICSEARCH_VERSION} \
    && gradle assemble --stacktrace

EXPOSE 9200
