## Crosslink `consul` and `vault`

Next up is creating the vault PKI mount and configuring its TLS cert.

### Prerequisites

You will need to have a root CA.  If you've used the consul agent CA,
it is recommended to move to an offline CA at this point.  [`easy-rsa`][1]
can simplify the process of creating an offline CA.  A LUKS encrypted,
air-gapped raspberry pi can do nicely for this (though it will be slow).
If you do use a rpi, ensure you're using the hwrng.

I will assume you're using [`easy-rsa`][1] for this guide.  If you are
not, I will instead assume that you know what you're doing and can
make the appropriate adjustments for your design.

## Getting Started

### Download [`easy-rsa`][1]

We will be using git to ensure the transfer from the internet to
the air gapped device is successful and not tampered with.  You will need
to somehow find a way to trust the committer's signature in this process.

```bash
# let's use a temp directory to keep the clutter down.
# this _can_ be in /tmp since we're going to use signature validation
# of the git commit that we're building the CA from but I'm choosing my
# home directory and will clean it up after.  Alternatively, keep a copy
# on your laptop if you ever need a clean copy and you're worried the
# repo will ever be unavailable to you when you need it.  Up to you.

mkdir ~/my-temp-dir
cd ~/my-temp-dir
git clone https://github.com/OpenVPN/easy-rsa
tar zcvf easy-rsa.tar.gz easy-rsa
```

### Install on air-gapped device

Copy the tarball to a USB stick and transfer it to your air-gapped device.

Now untar it and verify integrity:

```bash
tar zxvf easy-rsa.tar.gz
cd easy-rsa
git checkout v3.0.8  #or another release
git verify-commit HEAD
```

### And create a CA

Prefer the directions in the repo but here is a quick overview of things:

```bash
cd easyrsa3  #from within easy-rsa
cp vars.sample vars
# edit vars
./easyrsa init-pki
./easyrsa build-ca  #answer the questions
```

## Create your vault PKI mount and prepare your CSR

You will need to insert a usb stick to transfer the CSR to your air-gapped
machine.  We'll assume it's on /mnt.  Adjust your command accordingly.

```bash
# back to our project...
cd crosslink  #if you're not there already reading this README
terraform apply -auto-approve
cp consul_pki_ca.csr /mnt/
umount /mnt  #or diskutil unmountDisk USBSTICK or whatever for your OS
```

## Sign your CSR

Back on your air-gapped device, mount the USB stick.  We'll assume /mnt.

```bash
# make a unique REQNAME.  you can do this however you want.  this version
# requires GNU coreutils
REQNAME="consul-pki-vault-ica-$(date -Isecond)"
./easyrsa import-req /mnt/consul_pki_ca.csr "$REQNAME"
./easyrsa show-req "$REQNAME"
# verify the request is as it should be
./easyrsa sign-req ca "$REQNAME"
# copy the signed cert back to the USB stick and unmount it.
cp pki/issued/$REQNAME.crt /mnt/consul_pki_ca.pem
cp pki/ca.crt /mnt/ca.pem
umount /mnt  # again, adjust to suit your OS
```

## Install it in your vault PKI mount.

```bash
# back in crosslink!  cd if you're not there already.
cd crosslink
cp /mnt/ca.pem .
cat /mnt/consul_pki_ca.pem ca.pem > consul_pki_ca.pem
terraform apply -auto-approve
```

[1]: https://github.com/OpenVPN/easy-rsa
