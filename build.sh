#!/usr/bin/env bash

set -eu

mkdir -p dist

sh ./mvnw -B package

cp collection-service/target/*.war dist/
cp starship-service/target/starship-service-1.0.0.jar dist/
cp api-gateway/target/api-gateway-1.0.0.jar dist/
