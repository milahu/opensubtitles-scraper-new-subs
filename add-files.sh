#!/usr/bin/env bash

# add subtitle zipfiles to this repo

# based on opensubtitles-scraper/new-subs-push.py



# exit on error
set -e

# debu: trace all commands
#set -x



# get absolute paths of files
files=()
for file_path in "$@"; do
  files+=("$(readlink -f "$file_path")")
done



# change to the new-subs-repo git repo
cd "$(dirname "$0")"



if ! [ -d nums ]; then
  # create parent dir for worktree dirs
  mkdir -p nums
fi



files_added=false

for file_path in "${files[@]}"; do

  echo "adding file: $file_path"

  old_name="$(basename "$file_path")"
  new_name="$(echo "$old_name" | sed -E 's/(.*)\.\(([0-9]+)\)\.zip$/\2.\1.zip/')"

  num=$(echo "$new_name" | cut -d. -f1)

  if grep -q "^$num." files.txt; then
    echo "ignoring file: $new_name"
    continue
  fi

  worktree_path="nums/$num"

  if [ -d "$worktree_path" ]; then
    echo "removing old worktree $worktree_path"
    git worktree remove "$worktree_path"
  fi

  # mount worktree
  git worktree add --quiet --detach --no-checkout "$worktree_path"

  # create new orphan branch
  branch_name="nums/$num"
  git -C "$worktree_path" checkout --quiet --orphan "$branch_name"
  git -C "$worktree_path" reset
  git -C "$worktree_path" clean -fdq

  # add file
  cp "$file_path" "nums/$num/$new_name"
  git -C "$worktree_path" add "$new_name"
  echo '*.zip -delta' >"nums/$num/.gitattributes"
  git -C "$worktree_path" add .gitattributes
  git -C "$worktree_path" commit --quiet -m "add $num"
  git worktree remove "$worktree_path"
  echo "$new_name" >>files.txt
  git add files.txt
  git commit --quiet -m "files.txt: add $num"

  files_added=true

done



if $files_added; then

  echo pushing all branches
  #git push --all --force
  git push --all

fi
