#!/usr/bin/env bash

set -e

if [ $# != 1 ]; then
  echo error: missing argument
  echo
  echo usage:
  echo ./remove-shards.sh shards/12xxxxx/
  exit 1
fi

path_list=()
for arg in "$@"; do
  if ! [ -d "$arg" ] || ! echo "$arg" | grep -q -E '^shards/[0-9]+xxxxx/?$'; then
    echo "error: bad argument: ${arg@Q}"
    echo "arg must be path to shards dir, for example shards/12xxxxx/"
    exit 1
  fi
  path_list+=("$arg")
done

for path in "${path_list[@]}"; do
    # path: shards/12xxxxx/
    git worktree remove "$path"
    branch_name="shards-$(basename "$path")" # shards-12xxxxx
    # shards-12xxxxx -> origin/shards-102xxxxx
    # delete local branches
    git branch --all --format="%(refname:short)" |
    grep -m1 -E -e "^$branch_name$" -e "/$branch_name$" |
    while read -r branch; do
        echo "deleting local branch $branch"
        if [ "$branch" = "$branch_name" ]; then
            git branch --delete "$branch"
        else
            git branch --delete --remote "$branch"
        fi
    done
    # delete remote branches
    for remote in $(git remote show); do
        echo "deleting remote branch $branch_name from remote $remote"
        git push "$remote" --delete "$branch_name"
    done
done

echo ok
