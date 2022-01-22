# Create a hashistack in docker

## Getting Started

### Overview

There are a number of steps to get started but they're mostly simple and are
involved with preserving security during the bootstrap process.  As such, you
won't need to think too much and are typing commands only to keep terraform
from keeping it in state.

Here are the steps in brief:

1) configure docker networking
2) generate a gossip encryption key
3) generate acl tokens
4) generate tls certs
5) configure your terraform providers
6) configure your network's DNS to use consul

There is also a `bootstrap-repo.sh` that you may use if you're planning to
use a 3 consul host, 3 vault host cluster.

## The Steps

### Prerequisites

You will need at least one _Linux_ docker host.  It must be linux because it
expects a macvlan network.  This allows each docker container to have its own
IP address on your LAN.  For testing, you may use any docker network but you
will need to assign static IPs within the docker network, even if it's the
default NATted network (this is because the automation presented here expects
you to want a static IP for consul for DNS to work reliably -- if you don't
want to build a docker-based hashistack, you probably want to use one of the
more traditional approaches provided in Hashicorp's documentation).

For help setting that up, see my related [`docker_macvlan_bridge`][1] ansible role.

### Generate a consul key

You will need to make a consul bootstrap key.  The most reliable way to
document doing this this is via the consul docker container as described below
but any machine with consul can also do this via `consul keygen`.

```bash
docker run consul keygen
```

### Generate a management acl token

This deployment solution for consul relies on a precreated acl token for management
to avoid the secret 0 problem and staged rollout problem created by normal
bootstrapping.  You will only need one token to get started.

```bash
uuid -v 4
```

### Configure your variables

You may configure your variables however you like.  I use the terraform.tfvars
file.

The variables which need to be set are available in vars.tf

### Generate TLS certs

You will need to generate some certs to bootstrap the cluster.  In the example below,
`10.0.0.2`, `10.0.0.3`, `10.0.0.4` are the consul servers.
`10.0.1.2`, `10.0.1.3`, `10.0.1.4` are the vault servers.
`dc1` is the datacenter name.
`consul` is the domain name.

```bash
consul tls ca create
consul tls cert create -client -additional-ipaddress=10.0.1.2 -additional-ipaddress=10.0.1.3 -additional-ipaddress=10.0.1.4 -additional-dnsname=vault.service.consul
nonsul tls cert create -server -additional-ipaddress=10.0.0.2 -additional-ipaddress=10.0.0.3 -additional-ipaddress=10.0.0.4 -additional-dnsname=consul.service.consul
```

### Configure your `providers.tf`

This was tested with ssh access to docker hosts.  You will need to set up your
docker hosts for this and the user with which you connect for direct access to
docker (i.e., no typing `sudo docker` when you login by hand -- `docker ps`
must work).

You _may_ use the same host for all three `hashistack1-3` hosts.  You will need
to duplicate the provider for this to work.

### Configure your network

You need to forward all `.consul` dns traffic to your consul cluster before
spinning up terraform.  Lookups will fail until the cluster is up but will
begin to work as soon as terraform finishes applying if everything is working
properly.

This setting is sometimes called a forwarder, resolver, recursive resolver,
or conditional forwarder.

### Run terraform!


#### Deploy consul

You will need to change to the consul directory to bootstrap consul first.

```bash
cd consul
terraform apply -parallelism=1
cd ..
```

#### Test DNS in your network

This must work from your deployment host before vault can be provisioned
because DNS is used to decouple the terraform state for consul from the vault
deployment.

```bash
dig consul.service.consul
```

### Deploy vault

```bash
cd vault
terraform apply -parallelism=1
cd ..
```

### Bootstrap vault

NOTE: If you are recovering from a disaster, you will perform recovery steps
instead of bootstrapping vault.  Continue here if you're not planning on
restoring a consul snapshot.  Continue in Recovery if you will be restoring
consul instead of bootstrapping an empty vault.

Your vault service won't be ready to use yet and it also won't work via its
intended `vault.service.consul` address yet.  This is because none of the vault
servers will be unsealed since they won't have any configuration at all.

You may bootstrap the cluster either via the IP address using the vault CLI or
more simply, you can navigate to https://vault-ip:8200/ and do it there.  This
is the purpose of the -additional-ipaddress flags during TLS cert generation.

You may bootstrap on any of the vault hosts that you've configured and the
tokens will propagate to all vault servers via the consul backend.

### Finalizing the deployment

Save your generated configuration files to ease redeployment later.  Save them
somewhere safe like a password manager.

WARNING: These files give the holder the ability to completely subvert consul's
security.

```
terraform.tfvars
providers-local.tf
consul-agent-ca-key.pem
consul-agent-ca.pem
dc1-client-consul-*.pem
dc1-server-consul-*.pem
```

## Recovery

See [`RESTORE.md`][2]

## Notes

### docker provider

#### Locking/Racing/Too-much-at-once-ism

The docker provider used for this project currently (Jan 2022) cannot prevent
itself from creating error situations where the docker host is being asked to
do two things at the same time which must happen in serial.  Things like
downloading multiple images at the same time are an example.  This requires you
to use `-parallelism=1` to avoid the issue.  If you forget to use this flag,
terraform may work anyway but it may also fail with an obscure error about
docker exiting.  If you have a default ssh config, it may also spit out a
message about xauth which is the reddest of herrings.

#### Memory requirements of parallelism

If your target host is relatively low memory (<4G), you should limit
parallelism anyway so that docker clients won't OOM your host while refreshing
state.  This can be done with `terraform xxxxx -parallelism=1` or similar but
since the provider seems to create situations where docker fails due to running
commands at the same time which must be queued, this issue currently will not
be seen.

### `providers-local.tf`

This is active terraform configuration that I use.  To keep it reusable for others, I
keep my actual providers in `providers-local.tf`.  

If you would like to track upstream without conflicts, you can also copy the example
providers (`hashistack1-3`) into your own `providers-local.tf`.


[1]: https://github.com/jamesandariese/ansible-docker-macvlan-trunk
[2]: ./RESTORE.md
