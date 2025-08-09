#!/usr/bin/env bash

set -e
# set -x # debug

cd "$(dirname "$0")"

declare -A worktree_set
if [ -e .git/worktrees ]; then
  for dir in .git/worktrees/*; do
    worktree="$(cat "$dir"/gitdir)"
    # remove "/.git" suffix
    worktree="${worktree:0: -5}"
    worktree="$(realpath "$worktree")"
    worktree_set["$worktree"]=1
  done
fi

# mount all branches
while read branch; do
  # a: shards-102xxxxx
  # b: shards/102xxxxx
  branch_name=${branch##*/} # "origin/shards-102xxxxx" -> "shards-102xxxxx"
  dir=${branch_name/-/"/"}
  worktree="$(realpath -m "$dir")" # get absolute path
  if [ "${worktree_set[$worktree]}" = 1 ]; then # this breaks "set -u"
    # already mounted
    continue
  fi
  # "worktree add" fails if worktree exists
  git worktree add $dir $branch || continue
done < <(
  # note: also match "origin/shards-102xxxxx" etc
  git branch --all --format="%(refname:short)" |
  grep -E -e '^shards-[0-9]+xxxxx$' -e '/shards-[0-9]+xxxxx$'
)
