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

### Generate a `consul.key`

You will need to make a consul bootstrap key.  The most reliable way to
document doing this this is via the consul docker container as described below
but any machine with consul can also do this via `consul keygen`.

```bash
docker run consul keygen > consul.key
```

### Generate acl tokens

This solution creates acl tokens for management and vault.  These are pregenerated
and so you must pregenerate them to keep them secure.  Here's a way to do so if
you have a `uuid` command available.  `sudo apt-get install -y uuid` for debian
which can be run in docker.  Be sure to use a random UUID (v4).

```bash
printf '{
    "management": {
         "secret": "%s",
         "accessor": "%s"
    },
    "vault": {
         "secret": "%s",
         "accessor": "%s"
    },
    "anonymous": {
         "secret": "anonymous",
         "accessor": "00000000-0000-0000-0000-000000000002"
    }
}' `uuid -v 4` `uuid -v 4` `uuid -v 4` `uuid -v 4` > tokens.json
```

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

### Configure your variables

You may configure your variables however you like.  I use the terraform.tfvars
file.

The variables which need to be set are available in vars.tf

### Configure your network

You need to forward all `.consul` dns traffic to your consul cluster before
spinning up terraform.  Lookups will fail until the cluster is up but will
begin to work as soon as terraform finishes applying if everything is working
properly.

This setting is sometimes called a forwarder, resolver, recursive resolver,
or conditional forwarder.

### Run terraform!

```terraform apply```

### Bootstrap vault

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
consul.key
terraform.tfvars
providers-local.tf
tokens.json
consul-acl-bootstrap.json
consul-agent-ca-key.pem
consul-agent-ca.pem
dc1-client-consul-*.pem
dc1-server-consul-*.pem
```

## Recovery

If you should need to reinstall your cluster, for example because you have no
cluster due to a disaster, you may do so by rerunning this terraform fresh and
restoring a consul snapshot (operationalizing consul beyond bringing it up is
outside the scope of this project but suffice it to say, "backup your data".)

Before starting this process, recreate your tokens.json file with the original
tokens which will be restored in the snapshot.

If you've lost your tokens.json file, you will end up installing new tokens
and distributing them to vault.  Restoring the consul snapshot will then overwrite
the new tokens causing vault to fail.  You may either recreate your tokens.json
and then rerun the terraform or use the `reinstall-tokens.sh` script to bring
the tokens back.  You may find that there are consul agents which can't connect
due to node-id mismatches or other problems.  Use force-leave to get rid of them
and docker restart the affected containers until things work properly.  This
process is messy so the best bet is to not get in this situation.

## Notes

### docker provider with ssh

This provider has exited on me for no apparent reason many times.  Just rerun terraform.

If your target host is relatively low memory (<4G), you should also limit parallelism
so that docker clients won't OOM your host while refreshing state.  This can be done
with `terraform xxxxx -parallelism=1` or similar.

### `providers-local.tf`

This is active terraform configuration that I use.  To keep it reusable for others, I
keep my actual providers in `providers-local.tf`.  

If you would like to track upstream without conflicts, you can also copy the example
providers (`hashistack1-3`) into your own `providers-local.tf`.


[1]: https://github.com/jamesandariese/ansible-docker-macvlan-trunk
