#!/usr/bin/env bash

set -eux

cd "$(dirname "$0")"

./git-pull.sh
./mount-branches.sh
