locals {
    ready = alltrue([
        module.bootstrap-consul-server.ready,
        module.bootstrap-consul-client.ready,
        module.bootstrap-vault-server.ready,
    ])
    ready_message = <<-EOF
        All of your certs are ready.  Please do not delete the CSRs or
        else this terraform will want to recreate them which will
        be confusing.  (Do what you want... but dragons).
        EOF

    not_ready_message = <<-EOF
        The CSRs shown in terraform output must be signed before this
        process is complete.  Please sign the CSRs at each read_csr_path
        and place the signed certificate at the associated write_pem_path.
        
        There is a shar-style script for sending and receiving the data.
        Use it by copy pasting it, moving send.sh to your USB stick,
        copying it from your USB stick on your airgapped CA to your
        easy-rsa folder (next to pki/), running it, moving return.sh
        back to your USB stick, and running that from this bootstrap
        folder.

        Run the script in make-sender.sh
        EOF
}

output "ready" {
    value = local.ready
}
output "message" {
    value = local.ready ? local.ready_message : local.not_ready_message
}
