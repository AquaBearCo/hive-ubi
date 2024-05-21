# Use UBI as base image
FROM registry.access.redhat.com/ubi8/ubi as base

# Install necessary packages
RUN dnf install -y gzip tar wget && \
    dnf clean all 


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
    #rm -rf /opt/apache-hive-$HIVE_VERSION-bin/jdbc/* && \
    tar -xzvf /opt/apache-tez-$TEZ_VERSION-bin.tar.gz -C /opt && \
    rm -rf /opt/apache-tez-$TEZ_VERSION-bin/share/* 
    


FROM eclipse-temurin:8-ubi9-minimal as run 
USER root

ARG HADOOP_VERSION
ARG HIVE_VERSION
ARG TEZ_VERSION

COPY --from=base /opt/hadoop-$HADOOP_VERSION /opt/hadoop
COPY --from=base /opt/apache-hive-$HIVE_VERSION-bin /opt/hive
COPY --from=base /opt/apache-tez-$TEZ_VERSION-bin /opt/tez

# Install necessary packages
RUN microdnf install -y fontconfig gzip tar nano wget procps-ng ca-certificates glibc-langpack-en net-tools && \
    microdnf clean all && \
	wget https://dlm.mariadb.com/3824147/Connectors/java/connector-java-3.4.0/mariadb-java-client-3.4.0.jar -o /opt/hive/lib/mariadb-java-client-3.4.0.jar && \
	cp /opt/hive/lib/mariadb-java-client-3.4.0.jar /opt/hive/lib/mariadb.jar && \
	cp /opt/hive/lib/mariadb-java-client-3.4.0.jar /opt/hive/lib/mysql.jar
    

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

ARG UID=1000
RUN adduser --no-create-home --uid $UID hive  && \
chown hive /opt/tez && \
    chown hive /opt/hive && \
    chown hive /opt/hadoop && \
    chown hive /opt/hive/conf && \
    mkdir -p /opt/hive/data/warehouse && \
    chown hive /opt/hive/data/warehouse && \
    mkdir -p /home/hive/.beeline && \
    chown hive /home/hive/.beeline 
	
USER hive
WORKDIR /opt/hive
EXPOSE 10000 10002 9083
ENTRYPOINT ["sh", "-c", "/entrypoint.sh"]



