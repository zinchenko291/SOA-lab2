#!/bin/sh
set -eu

truststore="$MULE_HOME/conf/collection-truststore.p12"
rm -f "$truststore"
keytool -importcert -noprompt -alias collection-ca \
    -file /certs/ca/root-ca.crt -keystore "$truststore" \
    -storetype PKCS12 -storepass changeit

exec "$MULE_HOME/bin/mule"
