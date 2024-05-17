#!/bin/bash

#
# Licensed to the Apache Software Foundation (ASF) under one or more
# contributor license agreements. See the NOTICE file distributed with
# this work for additional information regarding copyright ownership.
# The ASF licenses this file to You under the Apache License, Version 2.0
# (the "License"); you may not use this file except in compliance with
# the License. You may obtain a copy of the License at
#
#    http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

set -x

# Default version values
HIVE_VERSION=4.0.0
HADOOP_VERSION=3.4.0
TEZ_VERSION=0.10.3
REPO=aquabear

usage() {
    cat <<EOF 1>&2
Usage: $0 [-h] [-hadoop <Hadoop version>] [-tez <Tez version>] [-hive <Hive version>] [-repo <Docker repo>]
Build the Hive Docker image

Options:
  -h           Display this help message
  -hadoop      Build image with the specified Hadoop version
  -tez         Build image with the specified Tez version
  -hive        Build image with the specified Hive version
  -repo        Docker repository
EOF
}

# Parse command-line arguments
while [ $# -gt 0 ]; do
  case "$1" in
    -h)
      usage
      exit 0
      ;;
    -hadoop)
      shift
      HADOOP_VERSION=$1
      ;;
    -tez)
      shift
      TEZ_VERSION=$1
      ;;
    -hive)
      shift
      HIVE_VERSION=$1
      ;;
    -repo)
      shift
      REPO=$1
      ;;
    *)
      usage
      exit 1
      ;;
  esac
  shift
done

# Set SOURCE_DIR to the appropriate directory if needed
SOURCE_DIR=${SOURCE_DIR:-"./"}

# Create a temporary working directory
WORK_DIR="$(mktemp -d)"

# Set download URLs
HADOOP_URL="https://dlcdn.apache.org/hadoop/common/hadoop-$HADOOP_VERSION/hadoop-$HADOOP_VERSION.tar.gz"
TEZ_URL="https://dlcdn.apache.org/tez/$TEZ_VERSION/apache-tez-$TEZ_VERSION-bin.tar.gz"
HIVE_URL="https://dlcdn.apache.org/hive/hive-$HIVE_VERSION/apache-hive-$HIVE_VERSION-bin.tar.gz"

# Download Hadoop
echo "Downloading Hadoop from $HADOOP_URL..."
if ! curl --fail -L "$HADOOP_URL" -o "$WORK_DIR/hadoop-$HADOOP_VERSION.tar.gz"; then
  echo "Failed to download Hadoop, exiting..."
  exit 1
fi

# Download Tez
echo "Downloading Tez from $TEZ_URL..."
if ! curl --fail -L "$TEZ_URL" -o "$WORK_DIR/apache-tez-$TEZ_VERSION-bin.tar.gz"; then
  echo "Failed to download Tez, exiting..."
  exit 1
fi

# Download Hive
echo "Downloading Hive from $HIVE_URL..."
if ! curl --fail -L "$HIVE_URL" -o "$WORK_DIR/apache-hive-$HIVE_VERSION-bin.tar.gz"; then
  echo "Failed to download Hive, exiting..."
  exit 1
fi

# Copy necessary files to the working directory
cp -R "$SOURCE_DIR/conf" "$WORK_DIR/"
cp "$SOURCE_DIR/entrypoint.sh" "$WORK_DIR/"
cp "$SOURCE_DIR/Dockerfile" "$WORK_DIR/"

# Build the Docker image
docker build \
  "$WORK_DIR" \
  -f "$WORK_DIR/Dockerfile" \
  -t "$REPO/hive-ubi8:$HIVE_VERSION" \
  --build-arg "BUILD_ENV=base" \
  --build-arg "HIVE_VERSION=$HIVE_VERSION" \
  --build-arg "HADOOP_VERSION=$HADOOP_VERSION" \
  --build-arg "TEZ_VERSION=$TEZ_VERSION"

# Clean up
rm -r "${WORK_DIR}"
