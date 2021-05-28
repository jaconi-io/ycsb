#!/usr/bin/env sh

# Download Apache HBase from the closest mirror.
curl --remote-name --location "https://www.apache.org/dyn/mirrors/mirrors.cgi?action=download&filename=hadoop/common/hadoop-${HADOOP_VERSION}/hadoop-${HADOOP_VERSION}.tar.gz"

# Download signature and keys.
curl --remote-name "https://downloads.apache.org/hadoop/common/hadoop-${HADOOP_VERSION}/hadoop-${HADOOP_VERSION}.tar.gz.asc"
curl --remote-name "https://downloads.apache.org/hadoop/common/KEYS"

# Verify download.
gpg --import KEYS
gpg --verify "hadoop-${HADOOP_VERSION}.tar.gz.asc" "hadoop-${HADOOP_VERSION}.tar.gz"

# Extract archive and move to destination.
tar --extract --gzip --file "hadoop-${HADOOP_VERSION}.tar.gz"
mv "hadoop-${HADOOP_VERSION}" "hadoop"

# Cleanup.
rm "hadoop-${HADOOP_VERSION}.tar.gz"
rm "hadoop-${HADOOP_VERSION}.tar.gz.asc"
rm "KEYS"
