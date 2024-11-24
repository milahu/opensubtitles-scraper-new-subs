#!/usr/bin/env bash

cd "$(dirname "$0")"

declare -A worktree_set
for dir in .git/worktrees/*; do
  worktree="$(cat "$dir"/gitdir)"
  # remove "/.git" suffix
  worktree="${worktree:0: -5}"
  worktree="$(realpath "$worktree")"
  worktree_set["$worktree"]=1
done

# mount all branches
while read branch; do
  # a: shards-102xxxxx
  # b: shards/102xxxxx
  dir=${branch/-/"/"}
  worktree="$(realpath "$dir")"
  if [ "${worktree_set[$worktree]}" = 1 ]; then
    # already mounted
    continue
  fi
  # "worktree add" fails if worktree exists
  git worktree add $dir $branch || continue
done < <(
  git branch --format="%(refname:short)" |
  grep -E '^shards-[0-9]+xxxxx$'
)
