#!/usr/bin/env bash
set -euo pipefail
WORKDIR="${WORKSPACE:-/home/kavia/workspace/code-generation/simple-notes-application-219608-219618/notes_backend}"
cd "$WORKDIR"
# check java
if command -v java >/dev/null 2>&1; then ver=$(java -version 2>&1 | awk -F '"' 'NR==1{print $2}' || true); major=$(echo "${ver:-0}" | awk -F. '{print ($1=="1")? $2 : $1}'); else major=0; fi
if [ "$major" -lt 17 ]; then sudo apt-get update -q && sudo DEBIAN_FRONTEND=noninteractive apt-get install -yq openjdk-17-jdk; fi
# validate javac
if ! command -v javac >/dev/null 2>&1; then sudo apt-get update -q && sudo DEBIAN_FRONTEND=noninteractive apt-get install -yq openjdk-17-jdk; fi
JAVA_BIN="$(readlink -f "$(command -v java)")"
JAVA_HOME="$(cd "$(dirname "$(dirname "$JAVA_BIN")")" && pwd)"
[ -x "$JAVA_HOME/bin/java" ] || { echo "ERROR: JAVA_HOME/bin/java missing ($JAVA_HOME)" >&2; exit 11; }
[ -x "$JAVA_HOME/bin/javac" ] || { echo "ERROR: javac missing in $JAVA_HOME/bin" >&2; exit 12; }
# check mvn
if ! command -v mvn >/dev/null 2>&1; then sudo apt-get update -q && sudo DEBIAN_FRONTEND=noninteractive apt-get install -yq maven; fi
MAVEN_BIN="$(readlink -f "$(command -v mvn)")"
MAVEN_HOME="$(cd "$(dirname "$(dirname "$MAVEN_BIN")")" && pwd)"
mvn_ver=$(mvn -v 2>/dev/null | awk '/Apache Maven/ {print $3}' || true)
mvn_major=$(echo "${mvn_ver:-0}" | awk -F. '{print $1}')
# require mvn >=3.8 (major 3 and at least 3.8.x is recommended; we check major >=3 and accept typical apt 3.8+)
if [ -z "$mvn_ver" ] || [ "$mvn_major" -lt 3 ]; then echo "ERROR: mvn not usable or too old: $mvn_ver" >&2; exit 13; fi
# Persist evaluated homes (write literal evaluated paths)
sudo tee /etc/profile.d/java_maven.sh >/dev/null <<EOF
export JAVA_HOME="${JAVA_HOME}"
export MAVEN_HOME="${MAVEN_HOME}"
export PATH="${JAVA_HOME}/bin:${MAVEN_HOME}/bin:$PATH"
EOF
sudo chmod +x /etc/profile.d/java_maven.sh || true
# Persist safe defaults that do not override existing env vars
sudo tee /etc/profile.d/notes_env.sh >/dev/null <<'EOF'
# notes_backend defaults (only set if unset)
: "${PORT:=}"
: "${SPRING_PROFILES_ACTIVE:=}"
export PORT="${PORT:-8080}"
export SPRING_PROFILES_ACTIVE="${SPRING_PROFILES_ACTIVE:-dev}"
EOF
sudo chmod +x /etc/profile.d/notes_env.sh || true
# Source for current session
. /etc/profile.d/java_maven.sh || true
. /etc/profile.d/notes_env.sh || true
# output versions for audit
java -version 2>&1 | sed -n '1,2p'
mvn -v | sed -n '1,2p'
