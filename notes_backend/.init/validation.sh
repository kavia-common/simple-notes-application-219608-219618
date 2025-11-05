#!/usr/bin/env bash
set -euo pipefail
WORKDIR="${WORKSPACE:-/home/kavia/workspace/code-generation/simple-notes-application-219608-219618/notes_backend}"
cd "$WORKDIR"
PORT="${PORT:-8080}"
MAX_WAIT_SECS="${MAX_WAIT_SECS:-60}"
export MAVEN_OPTS="-Djava.security.egd=file:/dev/./urandom -Xms128m -Xmx512m"
PRJNAME="notes_backend"
LOG="/tmp/${PRJNAME}_$(id -u).log"
PID_FILE="/tmp/${PRJNAME}_$(id -u).pid"
# Ensure build
mvn -B -DskipTests package > target/validation_build.log 2>&1 || { echo "ERROR: mvn package failed; tail log" >&2; tail -n 200 target/validation_build.log >&2 || true; exit 31; }
# Find jar
JAR_FILE=$(ls target/*-SNAPSHOT.jar 2>/dev/null || true)
if [ -z "$JAR_FILE" ]; then JAR_FILE=$(ls target/*.jar 2>/dev/null | head -n1 || true); fi
[ -n "$JAR_FILE" ] || { echo "ERROR: no jar found in target/" >&2; exit 32; }
# Verify fat jar via 'jar' tool
if jar tf "$JAR_FILE" | grep -q "BOOT-INF"; then :; else echo "ERROR: jar doesn't contain BOOT-INF; not a fat jar" >&2; exit 33; fi
# Start jar and capture actual JVM PID
nohup java $MAVEN_OPTS -jar "$JAR_FILE" --server.port=$PORT > "$LOG" 2>&1 &
JVM_PID=$!
# Ensure we have the java process (if wrapper PID, locate child java)
sleep 0.5
if ps -p "$JVM_PID" -o comm= | grep -qi 'mvn\|bash'; then
  # find java child of JVM_PID
  child_java=$(pgrep -P "$JVM_PID" -f 'java' || true)
  if [ -n "$child_java" ]; then JVM_PID="$child_java"; fi
fi
echo "$JVM_PID" > "$PID_FILE"
# Wait for TCP
elapsed=0
while ! bash -c "</dev/tcp/127.0.0.1/$PORT" >/dev/null 2>&1; do sleep 1; elapsed=$((elapsed+1)); if [ "$elapsed" -ge "$MAX_WAIT_SECS" ]; then break; fi; done
if [ "$elapsed" -ge "$MAX_WAIT_SECS" ]; then echo "ERROR: port $PORT did not open in ${MAX_WAIT_SECS}s" >&2; tail -n 200 "$LOG" >&2 || true; kill "$JVM_PID" >/dev/null 2>&1 || true; exit 34; fi
# HTTP probe with timeouts
http_code=$(curl -s -o /dev/null -w "%{http_code}" --connect-timeout 5 --max-time 10 "http://127.0.0.1:$PORT/" || true)
if [ -z "$http_code" ] || [ "$http_code" -lt 100 ]; then echo "ERROR: HTTP probe failed (code=$http_code)" >&2; tail -n 200 "$LOG" >&2 || true; kill "$JVM_PID" >/dev/null 2>&1 || true; exit 35; fi
echo "OK: app started pid=$JVM_PID port=$PORT http_code=$http_code waited=${elapsed}s"
# Graceful shutdown of process tree
pkill -TERM -P "$JVM_PID" || true
kill -TERM "$JVM_PID" >/dev/null 2>&1 || true
wait_seconds=0
while kill -0 "$JVM_PID" >/dev/null 2>&1; do sleep 1; wait_seconds=$((wait_seconds+1)); if [ "$wait_seconds" -ge 10 ]; then pkill -KILL -P "$JVM_PID" || true; kill -KILL "$JVM_PID" >/dev/null 2>&1 || true; break; fi; done
rm -f "$PID_FILE" || true
echo "Stopped pid=$JVM_PID"
