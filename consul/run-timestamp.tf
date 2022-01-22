resource "time_static" "run" {}

locals {
    run_id = time_static.run.unix
    run_hash = sha256(time_static.run.id)
}
