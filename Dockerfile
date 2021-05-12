FROM openjdk:8-jre AS builder

ARG YCSB_VERSION=0.17.0
ENV DOCKERIZE_VERSION v0.6.1
ENV DEBIAN_FRONTEND noninteractive

COPY generate.sh generate.sh

# Install security updates and build dependencies.
RUN apt-get update \
 && apt-get --assume-yes upgrade \
 && apt-get --assume-yes install --no-install-recommends xmlstarlet \
 && apt-get clean \
 && rm -rf /var/lib/apt/lists/*

# Download YCSB and dockerize. Generate templates.
RUN curl --remote-name --location "https://github.com/brianfrankcooper/YCSB/releases/download/${YCSB_VERSION}/ycsb-${YCSB_VERSION}.tar.gz" \
    && tar --extract --gzip --file "ycsb-${YCSB_VERSION}.tar.gz" \
    && mv "ycsb-${YCSB_VERSION}" "ycsb" \
    && curl --remote-name --location "https://github.com/jwilder/dockerize/releases/download/${DOCKERIZE_VERSION}/dockerize-linux-amd64-${DOCKERIZE_VERSION}.tar.gz" \
    && tar --extract --gzip --file "dockerize-linux-amd64-${DOCKERIZE_VERSION}.tar.gz" \
    && ./generate.sh

FROM openjdk:8-jre

ENV PATH /opt/ycsb/bin:$PATH

COPY --from=builder /dockerize /usr/local/bin/dockerize
COPY --from=builder /ycsb /opt/ycsb
COPY --from=builder /hbase-site.xml.tmpl /opt/ycsb/hbase20-binding/conf/hbase-site.xml.tmpl
COPY --from=builder /core-site.xml.tmpl /opt/ycsb/hbase20-binding/conf/core-site.xml.tmpl
COPY --from=builder /hdfs-site.xml.tmpl /opt/ycsb/hbase20-binding/conf/hdfs-site.xml.tmpl
COPY log4j.properties /opt/ycsb/hbase20-binding/conf/log4j.properties
COPY slf4j-log4j12-1.7.30.jar /opt/ycsb/hbase20-binding/lib/slf4j-log4j12-1.7.30.jar

# Install security updates and runtime dependencies.
RUN apt-get update \
 && apt-get --assume-yes upgrade \
 && apt-get --assume-yes install --no-install-recommends python \
 && apt-get clean \
 && rm -rf /var/lib/apt/lists/*

ENTRYPOINT [ "dockerize", \
  "-template", "/opt/ycsb/hbase20-binding/conf/hbase-site.xml.tmpl:/opt/ycsb/hbase20-binding/conf/hbase-site.xml", \
  "-template", "/opt/ycsb/hbase20-binding/conf/core-site.xml.tmpl:/opt/ycsb/hbase20-binding/conf/core-site.xml", \
  "-template", "/opt/ycsb/hbase20-binding/conf/hdfs-site.xml.tmpl:/opt/ycsb/hbase20-binding/conf/hdfs-site.xml" ]
CMD [ "ycsb", "--help" ]
