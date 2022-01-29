#!/usr/bin/env bash

set -e

JSON="$(jq -c .)"

eval "$(echo "$JSON" | jq -r '
    @sh "CSR=\(.csr // "")",
    @sh "CERT=\(.cert // "")",
    @sh "RSA=\(.rsa_key // "")",
    @sh "FCSR=\(.csr_file // "")",
    @sh "FCERT=\(.cert_file // "")",
    @sh "FRSA=\(.rsa_key_file // "")",
    @sh "PASSWORD=\(.password // "")",
    @sh "FAIL_NO_FILE=\(.fail_no_file // true)",
@sh ""')"

COUNT=0
[ x"$CSR" != x ]  && COUNT=$(( COUNT + 1 ))
[ x"$CERT" != x ] && COUNT=$(( COUNT + 1 ))
[ x"$RSA" != x ]  && COUNT=$(( COUNT + 1 ))
[ x"$FCSR" != x ]  && COUNT=$(( COUNT + 1 ))
[ x"$FCERT" != x ] && COUNT=$(( COUNT + 1 ))
[ x"$FRSA" != x ]  && COUNT=$(( COUNT + 1 ))

printf '%s\n' "OIJWEF $JSON" >> /tmp/poop


if [ $COUNT -ne 1 ];then
    1>&2 echo "must specify ONE of csr, cert, rsa_key, csr_file, cert_file, or rsa_key_file (received $COUNT)"
    1>&2 echo "received $JSON"
    exit 1
fi

FAIL_NO_FILE=no
[ x"$FAIL_NO_FILE" = xno -o x"$FAIL_NO_FILE" = xfalse ] || FAIL_NO_FILE=yes

check_file() {
    if [ x"$1" = x ];then
        # this isn't a file to check so skip
        return 0
    fi

    if [ -f "$1" ];then
        return 0
    fi

    if [ "$FAIL_NO_FILE" = yes ];then
        1>&2 echo "$1 does not exist and file_no_file is true"
        return 1
    else
        echo '{"modulus":""}'
        exit 0
    fi
}

check_file "$FCSR"
check_file "$FCERT"
check_file "$FRSA"

[ x"$FCSR" != x ] && CSR="$(cat $FCSR)"
[ x"$FCERT" != x ] && CERT="$(cat $FCERT)"
[ x"$FRSA" != x ] && RSA="$(cat $FRSA)"

(
[ x"$CSR" != x ]  && openssl req  -noout -modulus -in <(echo -n "$CSR")
[ x"$CERT" != x ] && openssl x509 -noout -modulus -in <(echo -n "$CERT")
[ x"$RSA" != x ]  && openssl rsa  -noout -modulus -in <(echo -n "$RSA") -passin "pass:$PASSWORD"
) | cut -d = -f 2 | jq -R '{"modulus":.}' | cat
