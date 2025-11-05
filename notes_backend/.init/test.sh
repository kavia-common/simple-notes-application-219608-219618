#!/usr/bin/env bash
set -euo pipefail
WORKDIR="${WORKSPACE:-/home/kavia/workspace/code-generation/simple-notes-application-219608-219618/notes_backend}"
cd "$WORKDIR"
TEST_FILE="src/test/java/com/example/notes/LightweightLoadTest.java"
mkdir -p "$(dirname "$TEST_FILE")"
if [ ! -f "$TEST_FILE" ]; then
  cat > "$TEST_FILE" <<'JAVA'
package com.example.notes;
import org.junit.jupiter.api.Test;
import static org.junit.jupiter.api.Assertions.assertDoesNotThrow;
class LightweightLoadTest {
  @Test
  void classLoads() {
    assertDoesNotThrow(() -> Class.forName("com.example.notes.NotesApplication"));
  }
}
JAVA
fi
mkdir -p target
if mvn -B -q test > target/test.log 2>&1; then echo "OK"; else echo "ERROR: tests failed; tail test log" >&2; tail -n 200 target/test.log >&2 || true; exit 22; fi
