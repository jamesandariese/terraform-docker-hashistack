## Testing

This setup script is designed for and tested on debian only.  There is probably
room to add vagrant or to test it with docker-in-docker or some similar thing but
no time or desire right now.

### What it do

This will create a docker network and spin the whole stack up on a single host.
This means it's different from the macvlan-based stuff but shouldn't be in any
significant ways.

### WARNING

Don't run this on a host currently running another of this stack.  At best, it
will fail.  Most likely, you will run teardown.sh and destroy part or all of
your stack.

Do not run this on a non-test host!  Just don't.

### Run the test

1) run `setup.sh`

2) ensure the exit status is 0 (good).  Alternatively, ensure the last few lines
   are 172.23.128.10, 172.23.128.11, 172.23.128.12.  These are IPs looked up
   from the test cluster that was spun up by setup.sh.

   A successful run of `setup.sh` indicates a successful test.

3) run `teardown.sh`

   This will delete the docker containers by name, the docker volumes by name,
   and the network it created, again by name.
