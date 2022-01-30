# `docker-hashistack`

See the demo at [asciinema](https://asciinema.org/a/QnAKUC1uf9UlYeKwlmNpTRjkX).

## Design

This is a dockerized hashistack.  It uses macvlan trunking in Linux and Docker
to achieve LAN connectivity for its containers.

### Goals

A reliable and operationally sound hashistack

Power and physical space efficiency

Good security

### Non Goals

Following the reference architecture exactly is not a goal of this project.
To achieve space as well as compute efficiency, we're using Docker to colocate
the services on a set of up to 3 hosts.  This is against the recommendation of
HashiCorp who would prefer that you deploy on separate hosts or at least on
VMs both of which will increase the system requirements of running the stack
as well as increase the operational overhead of maintaining this after-hours
stack.

## Prerequisites

You will need:

* An initialized CA which can sign an intermediate CA and client and server
  certs with IP and URL SANs (use [easy-rsa][easyrsa] for this)

We will assume:

* You're using a macbook.  If you're not, you probably will recognize how to
  modify the commands to work in Linux.  If you're using Windows, you're on
  your own... sorry.  Feel free to submit a PR with Windows instructions.
* You have a USB stick named `SneakerNet`.  This will be /Volumes/SneakerNet.
* All multiline instructions start at the root of the repo unless otherwise
  specified.
* You use vim.  I use vim, anyway.  Or emacs.  Or nano.  Or whatever is there.
  vim or at least vi is often there so I use it a lot.  `:q` to quit. `:wq` to
  save and quit.  `:q!` to quit without saving.  Check a quick reference if
  you need further help.
* You will only have a single datacenter and it will be dc1.  This is because
  the design goal of this repo is to make a power and space efficient
  hashistack, for a space constrained network (e.g., at home).

## Create your tfvars file

You will need to populate your tfvars.  Use terraform.tfvars.sample for a start
and use the tips.  

```
cp terraform.tfvars.sample terraform.tfvars
vim terraform.tfvars
```

## Bootstrap certs

First, get your root CA cert.  Put it on your SneakerNet stick.  It will be
named `ca.crt` in my examples.

```
cd bootstrap
cp /Volumes/SneakerNet/ca.crt ca.pem
terraform init
terraform apply
```

You should see `ready = false`.  This means that you've successfully generated
your keys and CSRs and are ready to get them signed.  There is a script for
aiding in this process:

```
bash make-sender.sh
cp send.sh /Volumes/SneakerNet/
```

Now, you've got a script containing the CSRs which we can transfer to our root
CA via SneakerNet stick.  `send.sh` takes the CSRs which were created and
registers them in your easy-rsa system.  It then signs them and exports them
via another shell script called `return.sh` which extracts the certificates
into the appropriate place when run from `bootstrap`, ready for the next
`terraform apply`.

NOTE: Use of this script is not necessary but can make the process
easier.  Ensure you trust the script that's created or skip using it (it's
very dense and weird -- feel free to skip using it or try it out first).

Regardless of your chosen method, you should have signed all your generated
CSRs and placed the signed certs in the associated paths:

```
# read CSR from here
# bootstrap-consul-client-read_csr_path = "./certs/bootstrap-consul-client.csr"
# write signed cert here
# bootstrap-consul-client-write_pem_path = "./certs/bootstrap-consul-client.pem"
```

Now terraform apply again to finish the bootstrapping process:

```
terraform apply
cd ..
```

You should see `ready = true`, indicating that you're done with the bootstrap
process and are ready to continue

## Deploy Consul

Now you'll deploy consul.  At the end, you'll have a 3 node consul cluster and
a 3 node DNS cluster which has special access to lookup all services.  The
consul cluster itself will not allow arbitrary lookups and will not listen on
port 53.

NOTE: Because this uses the docker provider in terraform, it is vulnerable to
contention when deploying many things at once.  For this reason, parallelism
must be limited to 1.

```
cd consul
terraform init
terraform apply -parallelism=1
# check the output of this to ensure it's your root CA.  We'll see it change
# later during testing of the vault CA change.
curl --cacert ../ca-certificates/bootstrap-ca.pem https://$(terraform output -json consul_addresses | jq -r '.[0]'):8501 -v 2>&1 |grep -E 'issuer:|subject:'
cd ..
```

NOTE: if your machines are very slow, the consul cluster may not be fully
initialized at the end.  Wait a minute and run terraform apply again.  If it still
doesn't work, investigate if you accidentally reused an IP.
```
Error: error creating ACL policy: Unexpected response code: 500 (No cluster leader)

  with consul_acl_policy.dns-lookups,
  on dns-servers.tf line 1, in resource "consul_acl_policy" "dns-lookups":
   1: resource "consul_acl_policy" "dns-lookups" {
```

## Deploy Vault

Next up is the vault deployment.


NOTE: Because this uses the docker provider in terraform, it is vulnerable to
contention when deploying many things at once.  For this reason, parallelism
must be limited to 1.

```
cd vault
terraform init
terraform apply -parallelism=1
```

### Initialize vault

These steps describe how to initialize vault via the CLI interface.  You may prefer
to use the web UI.  Feel free to do so.

This will not be automated because it is the single most exploitable
step in a production deployment.  You will be creating secrets which make your
vault storage readable by anyone with access to the storage and you'll also be
creating a root token for vault which can do anything.  These are your secrets;
keep them safe!

```
vault operator init -ca-cert=../ca-certificates/bootstrap-ca.pem -address="$(terraform output -raw vault_https)"
```
Save the output to somewhere secure like a password manager.

Now copy and paste the unseal keys and the token from where ever you saved
them.  For the first login command, you will paste the root token which you
just copied to your password manager.  For the second login command, vault will
generate a new token which will expire in 8 hours using the root token and it
will then save it to your filesystem.  This will still be a root token but the
token will expire and be useless if stolen.

```
vault operator unseal -ca-cert=../ca-certificates/bootstrap-ca.pem -address="$(terraform output -raw vault_https)"
vault operator unseal -ca-cert=../ca-certificates/bootstrap-ca.pem -address="$(terraform output -raw vault_https)"
vault operator unseal -ca-cert=../ca-certificates/bootstrap-ca.pem -address="$(terraform output -raw vault_https)"
vault login -ca-cert=../ca-certificates/bootstrap-ca.pem -address="$(terraform output -raw vault_https)"
vault login -method=token -ca-cert=../ca-certificates/bootstrap-ca.pem -address="$(terraform output -raw vault_https)" $(vault token create -ca-cert=../ca-certificates/bootstrap-ca.pem -address=`terraform output -raw vault_https` -field=token -ttl=8h)
```

All done with vault for now.  You will need to unseal all your vault servers to
achieve redundancy but you may do so at your leisure (if this isn't
production).

```
cd ..
```

## Link consul and vault to vault's TLS provider

Now you're going to deploy a TLS secret engine in vault which will be capable
of generating trusted certificates for the .consul domain.  This is the origin
of the name `consul-pki`.

Much of this process should also be followed to update the intermediate CA cert
in vault as needed.

```
cd consul-pki
terraform init
terraform apply
cp consul_pki_ca.csr /Volumes/SneakerNet
```

Sign the CSR with the same root CA from before.  You will need to ensure that you
sign it as a subordinate CA.  In easy-rsa, this is achieved with the following:

```
./easyrsa import-req consul_pki_ca.csr consul_pki_ca
./easyrsa sign-req ca consul_pki_ca
```

Now import the signed cert into your terraform and rerun terraform to import
the cert into vault.
```
cp /Volumes/SneakerNet/consul_pki_ca.crt consul_pki_ca.pem
terraform apply
cd ..
```

## Test the deployment

These should all yield useful results.  If any do not, you will need to
troubleshoot your deployment.  If your digs timeout, your DNS forwarders may be
misconfigured.  If your digs NACK instead, you still may need to fix your
forwarders but it also may mean that your services are unhealthy.  Check
consul's web interface for info about any failing health checks.

```
cd consul
curl --cacert ../ca-certificates/bootstrap-ca.pem https://$(terraform output -json consul_addresses | jq -r '.[0]'):8501 -v 2>&1 |grep -E 'issuer:|subject:'
dig @$(terraform output -raw dns_server_a) consul.service.consul
dig consul.service.consul
dig vault.service.consul
```

[easyrsa]: https://github.com/OpenVPN/easy-rsa
