#!/usr/bin/env bash

# pull all git branches

set -eux

cd "$(dirname "$0")"

remote=https://github.com/milahu/opensubtitles-scraper-new-subs
main_branch=main

# pull the main branch separately
git pull "$remote"

branches=(
  # no: fatal: Refusing to fetch into current branch refs/heads/main of non-bare repository
  #$main_branch
  $(
    git ls-remote --heads "$remote" |
    sed 's|^.*refs/heads/||' |
    grep -E '^shards-[0-9]+xxxxx$'
  )
)

a=(git fetch --verbose "$remote")

for branch in "${branches[@]}"; do
  a+=("$branch:$branch")
done

a+=("$@")

printf ">"; printf ' %q' "${a[@]}"; echo
"${a[@]}"
