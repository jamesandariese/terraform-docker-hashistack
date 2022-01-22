## Restoration after disaster

Assuming you've got a backup.snap (if you don't, you're out of luck for
automated restore options), you can restore it to the cluster to restore
operations.  This is a simple operation which will restore all ACLs and data.
As such, it will Just Work after a terraform apply (for recreation) of all
affected assets.

Assumptions:
 * consul https address is `10.0.1.2`
 * your token is `root`
 * snapshot at `backup.snap`
 * consul's cert is rooted by `consul-agent-ca.pem`
 * your primary datacenter is `dc1`

```bash
consul snapshot restore -token=root \
    -http-addr=https://10.0.1.2:8501 \
    -tls-server-name=server.dc1.consul \
    -ca-file=consul-agent-ca.pem \
    backup.snap
```

If your backup.snap is recent enough, you should see no interruption.  As
with all disaster recovery, sufficient preparation is a requirement for
success.  If you do not have a recent enough snapshot for your ACLs to 
remain up to date, you may need to recreate them, recreate agent
containers (like vault's), remove and import resources into state, or other
nasty things.  Disaster recovery can be very complicated.

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
5) Destroy consul cluster
  * terraform destroy in repo/consul/
6) Recreate consul cluster
  * terraform apply in repo/consul/
7) Login to new consul cluster
  * ensure recreated consul cluster works
8) Check consul kv store to ensure it's blank
  * ensure recreated consul cluster is truly recreated
9) Restore consul snapshot from #5
  * this should restore all data and functionality
10) Check consul kv store to ensure it contains vault's data
  * you shouldn't need to login again because the ACL tokens will have carried
    over but if you do, then login again
11) Check that vault contains the key created in #4
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

This can happen to any container and is a fairly reasonable problem to have
when recreating the services.  This should only happen to a service which
has been reprovisioned following a disaster and occurs because the agent is
recreated and generates a new node-id in the process.  It will usually only
happen if the consul agent exits uncleanly (it will leave the cluster if it
exits cleanly) so you will probably not see this in testing unless you delete
the docker containers, kill -9 the processes, or use any other process which
doesn't allow them to exit cleanly.



[1]: https://learn.hashicorp.com/tutorials/consul/access-control-troubleshoot?utm_source=consul.io&utm_medium=docs#reset-the-acl-system
