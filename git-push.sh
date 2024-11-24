#!/usr/bin/env bash

# push all git branches

remote=https://github.com/milahu/opensubtitles-scraper-new-subs
main_branch=main

branches=(
  $main_branch
  $(
    git branch --format="%(refname:short)" |
    grep -E '^shards-[0-9]+xxxxx$'
  )
)

a=(git push "$remote")

for branch in "${branches[@]}"; do
  a+=("$branch:$branch")
done

a+=("$@")

printf ">"; printf ' %q' "${a[@]}"; echo
"${a[@]}"
