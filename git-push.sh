#!/usr/bin/env bash

# push all git branches

# FIXME use incremental git push to avoid errors on large git push

# set -eux

cd "$(dirname "$0")"

remote=https://github.com/milahu/opensubtitles-scraper-new-subs
main_branch=main

branches=(
  $main_branch
  $(
    # shards-102xxxxx
    # origin/shards-102xxxxx
    git branch --all --format="%(refname:short)" |
    grep -E '^shards-[0-9]+xxxxx$'
    # no. mount-branches.sh creates local branches from remote-tracking branches
    # grep -E -e '^shards-[0-9]+xxxxx$' -e '/shards-[0-9]+xxxxx$'
  )
)
# echo "branches:" "${branches[@]}"

a=(git push "$remote")

for branch in "${branches[@]}"; do
  dst_branch=${branch##*/}
  a+=("$branch:$dst_branch")
done

a+=("$@")

printf ">"; printf ' %q' "${a[@]}"; echo
"${a[@]}"
