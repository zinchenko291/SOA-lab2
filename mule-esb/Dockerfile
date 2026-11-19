FROM maven:3.9-eclipse-temurin-17 AS build

WORKDIR /build
COPY pom.xml mule-artifact.json ./
COPY src/ src/
RUN mvn -B -DskipTests package

FROM eclipse-temurin:17-jdk-jammy

ENV MULE_HOME=/opt/mule
COPY mule-standalone-4.9.0.tar.gz /tmp/mule.tar.gz
RUN mkdir -p "$MULE_HOME" \
    && tar -xzf /tmp/mule.tar.gz -C "$MULE_HOME" --strip-components=1 \
    && rm /tmp/mule.tar.gz

COPY --from=build /build/target/collection-proxy-1.0.0-mule-application.jar /opt/mule/apps/collection-proxy.jar
COPY docker-entrypoint.sh /usr/local/bin/mule-entrypoint
RUN chmod +x /usr/local/bin/mule-entrypoint

WORKDIR /opt/mule
EXPOSE 8084
ENTRYPOINT ["/usr/local/bin/mule-entrypoint"]
