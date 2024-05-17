# Use UBI as base image
FROM registry.access.redhat.com/ubi8/ubi-init as base

# Install necessary packages
RUN dnf install -y tzdata openssl curl ca-certificates fontconfig glibc-langpack-en gzip tar java-1.8.0-openjdk-headless nano wget && \
    # Set JAVA_HOME
    echo "export JAVA_HOME=$(dirname $(readlink -f $(which java) | sed 's|/bin/java||'))" >> /etc/profile && \
    echo "export PATH=\"\$JAVA_HOME/bin:\$PATH\"" >> /etc/profile && \
    # Create hive user and directories
    adduser --no-create-home --uid 1000 hive

# Copy archives
COPY hadoop-*.tar.gz /opt/
COPY apache-hive-*-bin.tar.gz /opt/
COPY apache-tez-*-bin.tar.gz /opt/

# Extract and clean up
ARG HADOOP_VERSION
ARG HIVE_VERSION
ARG TEZ_VERSION
RUN tar -xzvf /opt/hadoop-$HADOOP_VERSION.tar.gz -C /opt/ && \
    rm -rf /opt/hadoop-$HADOOP_VERSION/share/doc/* && \
    tar -xzvf /opt/apache-hive-$HIVE_VERSION-bin.tar.gz -C /opt/ && \
    rm -rf /opt/apache-hive-$HIVE_VERSION-bin/jdbc/* && \
    tar -xzvf /opt/apache-tez-$TEZ_VERSION-bin.tar.gz -C /opt && \
    rm -rf /opt/apache-tez-$TEZ_VERSION-bin/share/* && \
	mkdir -p /opt/hive/data/warehouse /home/hive/.beeline && \
    chown -R hive:hive /opt/hive/data/warehouse /home/hive/.beeline

# Set necessary environment variables
ENV HADOOP_HOME=/opt/hadoop \
    HIVE_HOME=/opt/hive \
    TEZ_HOME=/opt/tez \
    HIVE_VER=$HIVE_VERSION

ENV PATH=$HIVE_HOME/bin:$HADOOP_HOME/bin:$PATH

# Copy entrypoint and configuration
COPY entrypoint.sh /
COPY conf $HIVE_HOME/conf
RUN chmod +x /entrypoint.sh

USER hive
WORKDIR /opt/hive

EXPOSE 10000 10002 9083
ENTRYPOINT ["sh", "-c", "/entrypoint.sh"]
