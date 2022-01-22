## Restoration after disaster

Assuming you've got a backup.snap (if you don't, you're out of luck for
automated restore options), you can restore it to the cluster to restore
operations.  This is a simple operation which will restore all ACLs and data.
As such, it will Just Work after a terraform apply (for recreation) of all
affected assets.

Assumptions:
 * consul https address is `10.0.1.2`
 * your token is `e31690cf-cec7-46f5-9b1c-97ad079931b2` (get it from terraform.tfvars)
 * snapshot at `backup.snap`
 * consul's cert is rooted by `consul-agent-ca.pem`
 * your primary datacenter is `dc1`

First, setup your consul environment from `terraform.tfstate`:

```bash
cd consul #if you're not already there.
export CONSUL_HTTP_TOKEN="$(jq -r '.resources[]|select(.name == "wait_for_consul_bootstrap" and .module == "module.consul-a")|.instances[].attributes.triggers.management_token' terraform.tfstate)"
export CONSUL_HTTP_ADDR="https://$(jq -r '.outputs.consul_addresses.value[0]' terraform.tfstate):8501"
export CONSUL_CACERT=$PWD/../consul-agent-ca.pem
export CONSUL_TLS_SERVER_NAME=server.dc1.consul
```

Now restore your snapshot:
```bash
consul snapshot restore backup.snap
```

If your backup.snap is recent enough, you should see no interruption.  As
with all disaster recovery, sufficient preparation is a requirement for
success.  If you do not have a recent enough snapshot for your ACLs to 
remain up to date, you may need to recreate them, recreate agent
containers (like vault's), remove and import resources into state, or other
nasty things.  Disaster recovery can be very complicated.

One caveat is that the DNS containers will definitely not work properly if
recreated.  This is because the DNS containers were recreated and their tokens
were also recreated but were not in the original snapshot.  Just rerun
terraform after the snapshot restore to add the tokens that were created during
DR back to consul.

  1) run terraform apply again
    ```bash
    terraform apply -parallelism=1 -auto-approve
    ```


This process has been tested with the following process:

1) Create consul cluster
  * terraform apply in repo/consul/
2) Create vault cluster
  * terraform apply in repo/vault/
3) Bootstrap vault
  * navigate to https://10.0.2.2 (or whatever your vault's IP is)
4) Ensure vault works by creating a key
  * this will give us the ability to ensure vault functionality is restored
5) Take a snapshot
  * consul snapshot save in repo/
6) Destroy consul cluster
  * terraform destroy in repo/consul/
7) Recreate consul cluster
  * terraform apply in repo/consul/
8) Login to new consul cluster
  * ensure recreated consul cluster works
9) Check consul kv store to ensure it's blank
  * ensure recreated consul cluster is truly recreated
10) Restore consul snapshot from #5
  * this should restore all data and functionality
11) Rerun terraform apply in repo/consul/
  * fix tokens for dns nodes (add them again because they were destroyed during
    consul snapshot restore)
11) Check consul kv store to ensure it contains vault's data
  * you shouldn't need to login again because the ACL tokens will have carried
    over but if you do, then login again
12) Check that vault contains the key created in #4
  * you shouldn't need to login again for this either but if you see errors in
    the web interface then click logout in the top right and login again with
    the same info from #4.
  * once you've confirmed that the key exists and contains the correct data,
    you've confirmed that consul restortion will restore functionality to
    underlying services.

## Potential Issues

### ACL tokens not in sync

You may need to create new ACL tokens or perform the [consul bootstrap reset
process][1] to restore functionality.  Once this is done, you will either
recreate the tokens if they are still secure or generate new ones if they are
not.  If you must generate new tokens, you will need to also propagate them
to vault and to any other service using static tokens.  If you are using vault
to generate tokens for other services, you will only need to generate them for
vault and, once vault functionality is restored, you may use vault to generate
keys for services again.

If you've regenerated keys, you will need to set the new keys both for the
consul_sidecar container generated in repo/vault/ _as well as_ for the vault
consul secrets engine.

### A consul agent not coming up

If you are seeing a node ID collision in consul, the simplest solution is to
run a `force-leave` on one of the consul servers.  You may do so by sshing to
the host of the first consul server and running (e.g., for `consul-dns-a`)
`docker exec -ti consul-a_consul_server consul force-leave consul-dns-a`
and then restarting the docker container for the consul agent of the service.
You may also just restart the agent first and see if it works.  It might!

Here is a sample of a node ID collision:
```bash
2022-01-21T00:34:04.477Z [WARN]  agent: Syncing node info failed.: error="rpc error making call: failed inserting node: Error while renaming Node ID: "92666a8d-7ed8-52af-9a36-9825c9cbf449": Node name vault-b is reserved by node 1eaf0bc3-56a0-6d6b-0b02-4d78bee8e9c7 with name vault-b (10.0.2.3)"
```

This was resolved with the following command:
```bash
docker restart vault-b_consul_sidecar
```


This can happen to any container and is a fairly reasonable problem to have
when recreating the services.  This should only happen to a service which
has been reprovisioned following a disaster and occurs because the agent is
recreated and generates a new node-id in the process.  It will usually only
happen if the consul agent exits uncleanly (it will leave the cluster if it
exits cleanly) so you will probably not see this in testing unless you delete
the docker containers, kill -9 the processes, or use any other process which
doesn't allow them to exit cleanly.

## Terraform being obnoxious (ACL exists, no leader, etc)

Usually not terraform's fault per se.  But here's some stuff that will cause
hair pulling and only when running terraform.

### Failed to read policy ...

```
Error: Failed to read policy 'fac63669-cb76-8bcc-7fb0-bc35052eed8c': Unexpected response code: 500 (No cluster leader)
   with consul_acl_policy.dns-lookups,
...
```

You will see this sort of error any time you're attempting to use the consul
provider while consul is broken.  This will be pretty much every time after
you've deployed that you're interacting with it outside of upgrades so be
ready for it (example using the resource from the example error above...
adjust to suit your situation):

```
terraform state rm consul_acl_policy.dns-lookups
```

and retry your terraform apply/destroy.

### A policy with name... already exists

```
Error: error creating ACL policy: Unexpected response code: 500 (Invalid Policy: A Policy with Name "dns-lookups-1234567890" already exists)
```

This is because you had to `terraform state rm consul_acl_policy.dns-lookups`.
If this happens, you will also need to taint the time_static.run resource to
get it to generate new policy names.  You may also want to clean up your ACLs
in consul after.

```
terraform taint time_static.run
```

### Repeated TLS errors despite changing certificates

Because of how the bootstrap certs are replaced, if you attempt to 
`terraform apply` in the consul environment over an existing deployment,
you will not be updating the actual cert.pem, et al.  You will only
overwrite the bootstrap-cert.pem and related files but for safety, the cert.pem
file will not be overwritten on subsequent restarts of the container.  This
means that if the volume is preserved but the docker container is restarted
and a new bootstrap-cert.pem is uploaded, the cert will still not be replaced.

```
# don't forget to snapshot your cluster if it's still operational
terraform destroy;terraform apply
```

Fully reprovision the environment (or taint the volumes) to replace the certs.
This will probably mean restoring a snapshot, too, so take a snapshot first
if you can.


[1]: https://learn.hashicorp.com/tutorials/consul/access-control-troubleshoot?utm_source=consul.io&utm_medium=docs#reset-the-acl-system
