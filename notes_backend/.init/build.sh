#!/usr/bin/env bash
set -euo pipefail
WORKDIR="${WORKSPACE:-/home/kavia/workspace/code-generation/simple-notes-application-219608-219618/notes_backend}"
cd "$WORKDIR"
# JVM options tuned for headless container
export MAVEN_OPTS="-Djava.security.egd=file:/dev/./urandom -Xms128m -Xmx512m"
# Use workspace-local Maven repository for reproducible builds unless overridden
export MAVEN_USER_HOME="${MAVEN_USER_HOME:-$WORKDIR/.m2}"
mkdir -p "$MAVEN_USER_HOME" target
# Run Maven in batch mode; write logs to target/build.log on failure
if mvn -B -DskipTests package > target/build.log 2>&1; then
  echo "OK"
else
  echo "ERROR: build failed; tail log" >&2
  tail -n 200 target/build.log >&2 || true
  exit 21
fi
