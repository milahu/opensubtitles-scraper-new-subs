#!/usr/bin/env bash

git_user_name="Milan Hauth"
git_user_email="milahu@gmail.com"

cd "$(dirname "$0")"

# add one shard per commit to allow incremental "git push"

# undo previous "git add"
git restore --staged .

while read shard_path; do
  echo "shard_path $shard_path"
  shard_name=$(basename $shard_path .db)
  echo "shard_name $shard_name"
  #continue # dry run
  git add "$shard_path"
  git -c user.name="$git_user_name" -c user.email="$git_user_email" commit -m "add shard $shard_name"
  sleep 1
done < <(
  # note: temporary files are ignored by .gitignore
  git status --untracked-files=all shards/ --porcelain=2 | grep '^? ' | cut -c3-
)
