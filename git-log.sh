#!/usr/bin/env bash

# show git log of all branches, sorted by commit date

cd "$(dirname "$0")"

main_branch=main

branches=(
  $main_branch
  $(
    git branch --format="%(refname:short)" --all |
    grep -E '(^|/)shards-[0-9]+xxxxx$'
  )
)

for branch in "${branches[@]}"; do
  git log --format="%cI $branch %h %s" "$branch" | head -n100
done |
sort -r -k1 |
head -n20
