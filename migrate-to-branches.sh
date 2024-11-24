#!/usr/bin/env bash

# a: shards 10200xxx to 10299xxx are stored in ./shards/102xxxxx/
# b: shards 10200xxx to 10299xxx are stored in the git branch shards-102xxxxx

set -eux

cd "$(dirname "$0")"

shopt -s nullglob

now=$(date --utc +%Y%m%dT%H%M%SZ)

# create a backup of the main branch
git branch --copy main bak-main-$now

for dir in shards/*xxxxx; do

  echo "dir: $dir"

  # a: shards/102xxxxx
  # b: shards-102xxxxx
  branch=${dir/"/"/-}

  # copy fails if $branch exists
  git branch --copy main $branch || continue

  # move subdirectory $dir to root
  # https://github.com/newren/git-filter-repo/issues/70
  git filter-repo --force --refs $branch --subdirectory-filter $dir

done

# remove all dirs from the main branch
# note: files added after "git branch --copy" will be lost
a=(git filter-repo --force --refs main --invert-paths)
for dir in shards/*xxxxx; do
  a+=(--path "$dir")
done
"${a[@]}"

./mount-branches.sh
