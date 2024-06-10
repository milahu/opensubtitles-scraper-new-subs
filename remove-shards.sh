#!/usr/bin/env bash

set -e

if [ $# != 1 ]; then
  echo error: missing argument
  echo
  echo usage:
  echo ./remove-shards.sh shards/12xxxxx/
  exit 1
fi

if ! [ -d "$1" ] || ! echo "$1" | grep -q -E '^shards/[0-9]+xxxxx/?$'; then
  echo "error: bad argument: ${1@Q}"
  echo "argv[0] must be path to shards dir, for example shards/12xxxxx/"
  exit 1
fi

set -x

git checkout main

git branch bak-main-$(date --utc +%Y%m%dT%H%M%SZ)

time \
git-filter-repo --force --refs main --invert-paths --path "$1"

echo ok
