FROM maven:3.9-eclipse-temurin-17 AS build

WORKDIR /build
COPY pom.xml mule-artifact.json ./
COPY src/ src/
# Build-time AST generation requires the Enterprise runtime BOM.
RUN --mount=type=cache,id=soa-lab4-mule-maven,target=/root/.m2/repository,sharing=locked \
    mvn -B -DskipTests -DskipAST=true package

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
