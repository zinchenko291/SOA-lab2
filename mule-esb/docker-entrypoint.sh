#!/bin/sh
set -eu

if [ -z "${UPSTREAM_TRUSTSTORE:-}" ]; then
    truststore="$MULE_HOME/conf/upstream-truststore.p12"
    rm -f "$truststore"
    keytool -importcert -noprompt -alias upstream-ca \
        -file /certs/ca/root-ca.crt -keystore "$truststore" \
        -storetype PKCS12 -storepass changeit
fi

exec "$MULE_HOME/bin/mule"
