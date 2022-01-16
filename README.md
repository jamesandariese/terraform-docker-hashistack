# Create a hashistack in docker

## Getting Started

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

### generate a `consul.key`

You will need to make a consul bootstrap key.  The most reliable way to
document doing this this is via the consul docker container as described below
but any machine with consul can also do this via `consul keygen`.

```bash
docker run consul keygen > consul.key
```

### configure your `providers.tf`

This was tested with ssh access to docker hosts.  You will need to set up your
docker hosts for this and the user with which you connect for direct access to
docker (i.e., no typing `sudo docker` when you login by hand -- `docker ps`
must work).

You _may_ use the same host for all three `hashistack1-3` hosts.  You will need
to duplicate the provider for this to work.

### configure your variables

You may configure your variables however you like.  I use the terraform.tfvars
file.

### configure your network

You need to forward all `.consul` dns traffic to your consul cluster before
spinning up terraform.  Lookups will fail until the cluster is up but will
begin to work as soon as terraform finishes applying if everything is working
properly.

This setting is sometimes called a forwarder, resolver, recursive resolver,
or conditional forwarder.

### Run terraform!

```terraform apply```

### Bootstrap vault

Your vault service won't be ready to use yet and it also won't work via its intended
`vault.service.consul` address yet.  This is because none of the vault servers
will be unsealed since they won't have any configuration at all.  You may perform
this configuration by adding `your-vault-IP vault.service.consul` to /etc/hosts
and navigating to https://vault.service.consul:8200/ .  Setup the unseal key and root
token and save the output to somewhere secure like a password manager.  You will see
in consul that 

FIXME: https is current aspirational.  tls is disabled while I figure out how to
reliably _and_ securely bootstrap it.  Until that is accomplished, vault will not
be secure during bootstrap and any secrets sent to it over a network will be
readable by anyone with physical access to the network (or to a device with that
access).

## Notes

### docker provider with ssh

This provider has exited on me for no apparent reason many times.  Just rerun terraform.

If your target host is relatively low memory (<4G), you should also limit parallelism
so that docker clients won't OOM your host while refreshing state.  This can be done
with `terraform xxxxx -parallelism=1` or similar.

### providers-local.tf

This is active terraform configuration that I use.  To keep it reusable for others, I
keep my actual providers in `providers-local.tf`.  

If you would like to track upstream without conflicts, you can also copy the example
providers (`hashistack1-3`) into your own `providers-local.tf`.


[1]: https://github.com/jamesandariese/ansible-docker-macvlan-trunk
