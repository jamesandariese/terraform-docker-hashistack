data "local_file" "ca" {
    filename = "ca.pem"
}

resource "local_file" "ca" {
    filename = "${path.root}/../ca-certificates/bootstrap-ca.pem"
    content = data.local_file.ca.content
}
