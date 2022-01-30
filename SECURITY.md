# Security

This dockerized hashistack is meant to be as secure as reasonably possible
to network threats as well as physical threats.  As such, it should _not_
be possible to take any single physical host or the entire set, turn them
on, and get access to secrets.  This is one of the main reasons for
choosing vault.

The entire stack is designed to be run as a trusted core in your network,
running on physical devices which should have as much protection against
network intrusion as possible.  Put SSH to the hosts on a separate VLAN if
you can and don't install a GUI or any additional services.  Firewall all
ports except the ones you are intentionally running and only open them when
needed if possible.  If you can turn off ssh access using a GPIO switch
(if you're running this on a RPI or you can get access to the turbo button
or even caps lock), use that as well.  This should be as break-in proof
as possible.

These concerns are why these hosts should not run in a VM on an otherwise
untrusted host.  You _may_ run these on VMs but the VM host should then be as
well protected as possible too.  This is the reason for choosing Docker for
this project, in fact: less moving parts.  The downside to Docker however
is that there is also less of a barrier between the services.  All services
on the hosts must be as trustworthy as possible and should be necessary to
the functioning of the security of your network.  In this case, we're using
the following services for the following reasons:

* `vault`: provisioning and storage of secure credentials and secrets
* `consul`: service discovery via DNS, kv store, storage backend for `vault`
* `nomad`: trusted orchestrator which may distribute secrets from vault

## Offline Root CA

This system is expected to use an offline root CA.  If the physical hosts
are off for more than the TTL of the certs (24 hours by default) that are
generated for each service in vault, the system will need to be
bootstrapped again using the root CA or by ignoring TLS verification by
connecting to the hosts over SSH and modifying each container.

If you use an online root CA, especially if it's colocated with these
containers, you will not have the same protection against physical theft
and will need to rely on some other solution such as LUKS.

NOTE: The hosts can also be brought back up within the period of the
bootstrap certs.  If they are significantly long, this may negate the
downed host security described here.

## Terraform

For security with terraform, see GITREMOTE.md which describes how to use
an arbitrary (in this case, github) git remote with GPG to achieve strong
encryption atop an insecure git remote.
