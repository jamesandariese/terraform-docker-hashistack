# secure git remote usage

This project was designed to keep your security in house, literally.
One glaring flaw in this is that the tfstate has the keys to the
kingdom and there's no simple way to encrypt your remote state
client side while storing it locally and also tracking changes.

## `git-remote-gcrypt`

To work within the constraints of on-prem while tracking changes
and also maintaining zero trust where possible, we will use GPG to
encrypt the git repo itself, allowing you to send it anywhere you
prefer without sacrificing security.

We will setup a gcrypt repo and also setup a read-only remote
for tracking upstream changes.

### Setup

The first step will be to create an empty repo.  We'll use github
for this example.  Mine will be called `jamesandariese/hs2.022k`.

```bash
git clone https://github.com/jamesandariese/terraform-docker-hashistack hashistack
cd hashistack
git remote rename origin upstream
git remote set-url upstream --push "do not push to upstream"
git remote add origin gcrypt::git@github.com:jamesandariese/hs2.022k.git
```

### First use

After configuring this repo for the first time, you will have many additional
untracked files.  This is normal and the whole goal of this document.  Commit
them and push to your encrypted repo.  These are all your stack secrets and
sending them to an encrypted repo allows you to remove them from your laptop.

### Updating from upstream

To incorporate changes from upstream (assuming you're on main already):

```bash
git fetch upstream
git rebase upstream/main
# or
git merge upstream/main
```

If there are conflicts, you will need to resolve them.

### Deleting and restoring

When you're not working with the repo, you may wish to delete it from disk.
This will clear your remotes and you will need to set them up again.

```bash
git clone gcrypt::git@github.com:jamesandariese/hs2.022k.git my-own-hashistack
cd my-own-hashistack
bash add-upstream.sh
```

## Trouble and how to shoot it

### weird ioctl error

This is talked about on the interwebs but since there's a lot of layers here,
I'll add that the ioctl error like the following is because of pinentry.

Things like this:
```
gpg: public key decryption failed: Inappropriate ioctl for device
```

You can solve this in a few ways, one of which is telling GPG where your TTY
for pinentry can be found.

```bash
export GPG_TTY=$(tty)
```

You can also use a pinentry program for your OS and tell GPG about it:

```bash
brew install pinentry-mac
echo pinentry-program /usr/local/bin/pinentry-mac >> ~/.gnupg/gpg-agent.conf
```

NOTE: These are sample instructions.  Don't just paste them in but instead
understand them and then run something _similar_, possibly identical, for your
workspace.  The `brew install` shown above, for example, will output
instructions at the end of installation to say what should be done and those
instructions might change in time.  YMMV caveat emptor a rolling stone gathers
no entropy etc.
