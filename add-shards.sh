#!/usr/bin/env bash

cd "$(dirname "$0")"

# add one shard per commit to allow incremental "git push"

while read shard_path; do
  echo "shard_path $shard_path"
  shard_name=$(basename $shard_path .db)
  echo "shard_name $shard_name"
  #continue # dry run
  git add "$shard_path"
  git commit -m "add shard $shard_name"
  sleep 1
done < <(
  # note: temporary files are ignored by .gitignore
  git status shards/ --porcelain=2 | grep '^? ' | cut -c3-
)
