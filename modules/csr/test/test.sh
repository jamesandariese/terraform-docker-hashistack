#!/bin/bash

# RUN ME.  exit code is success of extract-modulus.sh external data provider test.

cd "$(dirname "$0")"

terraform destroy -auto-approve || true
terraform apply -auto-approve
terraform output -json modulii | jq -e '
(true
    and .ca_cert == .ca_key
    and .csrs == .certs
    and .certs == .keys
    and .no_file_modulus.modulus == ""
and true)
'
