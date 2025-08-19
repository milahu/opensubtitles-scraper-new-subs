#!/usr/bin/env bash

set -e
# set -x # debug

cd "$(dirname "$0")"

# add local branches from remote-tracking branches
# remote-tracking branches are created by the first "git clone"

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

declare -A done_branch_names

# mount all branches
while read branch; do
  # a: shards-102xxxxx
  # b: shards/102xxxxx
  branch_name=${branch##*/} # "origin/shards-102xxxxx" -> "shards-102xxxxx"
  if [ "${done_branch_names[$branch_name]}" = "1" ]; then continue; fi
  done_branch_names[$branch_name]=1
  dir=${branch_name/-/"/"}
  worktree="$(realpath -m "$dir")" # get absolute path
  if [ "${worktree_set[$worktree]}" = 1 ]; then # this breaks "set -u"
    # already mounted
    continue
  fi
  # "worktree add" fails if worktree exists
  git worktree add $dir $branch || true
  if [ "${branch:0:7}" = "origin/" ]; then
    echo "creating local branch $branch_name from remote-tracking branch $branch"
    git -C $dir checkout -b $branch_name
  fi
done < <(
  # local branches: "shards-102xxxxx" etc
  git branch --all --format="%(refname:short)" |
  grep -E '^shards-[0-9]+xxxxx$'

  # remote-tracking branches: "origin/shards-102xxxxx" etc
  git branch --all --format="%(refname:short)" |
  grep -E '/shards-[0-9]+xxxxx$'
)
