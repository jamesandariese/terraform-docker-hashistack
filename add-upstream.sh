#!/bin/bash

cd "$(dirname "$0")"
set -e
set -x

git remote add upstream https://github.com/jamesandariese/terraform-docker-hashistack.git
git remote set-url upstream --push "do not push to upstream"
