#!/usr/bin/env bash
set -euo pipefail
WORKDIR="/home/kavia/workspace/code-generation/simple-notes-application-219608-219618/notes_backend"
cd "$WORKDIR"
SPRING_BOOT_VERSION="${SPRING_BOOT_VERSION:-3.2.0}"
if [ ! -f pom.xml ]; then
  cat > pom.xml <<POM
<project xmlns="http://maven.apache.org/POM/4.0.0" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:schemaLocation="http://maven.apache.org/POM/4.0.0 http://maven.apache.org/xsd/maven-4.0.0.xsd">
  <modelVersion>4.0.0</modelVersion>
  <groupId>local.notes</groupId>
  <artifactId>notes-backend</artifactId>
  <version>0.0.1-SNAPSHOT</version>
  <parent>
    <groupId>org.springframework.boot</groupId>
    <artifactId>spring-boot-starter-parent</artifactId>
    <version>${SPRING_BOOT_VERSION}</version>
    <relativePath/>
  </parent>
  <dependencies>
    <dependency>
      <groupId>org.springframework.boot</groupId>
      <artifactId>spring-boot-starter-web</artifactId>
    </dependency>
    <dependency>
      <groupId>com.h2database</groupId>
      <artifactId>h2</artifactId>
      <scope>runtime</scope>
    </dependency>
    <dependency>
      <groupId>org.springframework.boot</groupId>
      <artifactId>spring-boot-starter-test</artifactId>
      <scope>test</scope>
    </dependency>
  </dependencies>
  <build>
    <plugins>
      <plugin>
        <groupId>org.springframework.boot</groupId>
        <artifactId>spring-boot-maven-plugin</artifactId>
      </plugin>
    </plugins>
  </build>
</project>
POM
fi
mkdir -p src/main/java/com/example/notes src/test/java/com/example/notes src/main/resources
if [ ! -f src/main/java/com/example/notes/NotesApplication.java ]; then
  cat > src/main/java/com/example/notes/NotesApplication.java <<'JAVA'
package com.example.notes;
import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
@SpringBootApplication
public class NotesApplication { public static void main(String[] args){ SpringApplication.run(NotesApplication.class, args); } }
JAVA
fi
if [ ! -f src/main/resources/application.properties ]; then
  cat > src/main/resources/application.properties <<'PROPS'
# leave server.port backable to environment
server.port=${PORT:--DPORT}
spring.h2.console.enabled=true
spring.datasource.url=jdbc:h2:mem:notesdb;DB_CLOSE_DELAY=-1
spring.datasource.driverClassName=org.h2.Driver
management.endpoints.web.exposure.include=health,info
PROPS
fi
