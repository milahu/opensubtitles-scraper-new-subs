#!/usr/bin/env bash

set -x

cd "$(dirname "$0")"

git reflog expire --expire-unreachable=now --all

time git gc --prune=now

exit $?
