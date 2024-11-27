#!/usr/bin/env bash

cfg=(
  -c user.name="Milan Hauth"
  -c user.email="milahu@gmail.com"
)

cd "$(dirname "$0")"

# mount all existing branches
#./mount-branches.sh

shopt -s nullglob

declare -A has_branch
while read branch; do
  has_branch[$branch]=1
done < <(
  git branch --format="%(refname:short)" |
  grep -E '^shards-[0-9]+xxxxx$'
)

declare -A has_worktree
declare -A worktree_of_branch
for dir in .git/worktrees/*; do
  worktree="$(cat "$dir"/gitdir)"
  #echo "dir: $dir"
  #echo "worktree 1: $worktree"
  # remove "/.git" suffix
  worktree="${worktree:0: -5}"
  #echo "worktree 2: $worktree"
  if ! [ -e "$worktree" ]; then
    echo "removing missing worktree $worktree"
    git worktree remove "$worktree"
    continue
  fi
  worktree="$(realpath "$worktree")"
  #echo "worktree 3: $worktree"
  has_worktree[$worktree]=1
  worktree_head="$(cat "$dir"/HEAD)"
  if [ "${worktree_head:0:16}" != 'ref: refs/heads/' ]; then
    echo "FIXME not recognized worktree_head ${worktree_head@Q}"
    exit 1
  fi
  worktree_head="${worktree_head:16}"
  worktree_of_branch[$worktree_head]="$worktree"
  #echo "worktree_of_branch[$worktree_head]=${worktree@Q}"
  worktree_short=$(realpath --relative-base="$PWD" "$worktree")
  echo "branch $worktree_head is mounted at $worktree_short"
done

# https://unix.stackexchange.com/a/567537
function version_greater_equal() {
  printf '%s\n%s\n' "$2" "$1" |
  sort --check=quiet --version-sort
}

git_version=$(git version)
git_version=${git_version/'git version '/}

# https://stackoverflow.com/a/79220337/10440128
function git_worktree_add_orphan() {
  # global git_version
  local path="$1"
  local branch="$2"
  if version_greater_equal "$git_version" 2.42; then
    # this requires git version 2.42
    git worktree add --orphan "$path" "$branch"
    return $?
  fi
  # this also works before git version 2.42
  git worktree add --detach --no-checkout "$path" || return $?
  local empty_tree=$(git hash-object -w -t tree /dev/null)
  local empty_commit=$(git commit-tree "$empty_tree" -m "empty tree")
  git -C "$path" checkout --orphan "$branch" "$empty_commit"
}

function git_branch_exists() {
  git branch --format="%(refname:short)" |
  grep -q -x -m1 "$1"
}

for dir in shards/*xxxxx; do

  bak_dir="$dir.bak-$(mktemp -u XXXXXXXX)"
  branch=${dir/"/"/-}
  worktree="$(realpath "$dir")"
  worktree_short=$(realpath --relative-base="$PWD" "$worktree")

  echo
  echo "dir: $dir"
  echo "bak_dir: $bak_dir"
  echo "branch: $branch"
  echo "worktree: $worktree_short"
  echo "has_branch[\$branch]=${has_branch[$branch]}"
  echo "has_worktree[\$worktree]=${has_worktree[$worktree]}"
  #continue # debug

  if [ "${has_branch[$branch]}" != 1 ]; then
    # git branch does not exist (and is not mounted)
    if [ -e "$dir" ]; then
      if ! [ -d "$dir" ]; then
        echo "error: worktree dir exists, but is not a directory: ${dir@Q}"
        exit 1
      fi
      echo "worktree dir exists. moving to ${bak_dir@Q}"
      mv -v "$dir" "$bak_dir"
    fi
    # create empty branch and mount it
    git_worktree_add_orphan "$dir" "$branch"
    has_branch[$branch]=1
    has_worktree[$worktree]=1
  elif [ "${has_worktree[$worktree]}" != 1 ]; then
    # git branch exists but is not mounted
    if [ -e "$dir" ]; then
      mv -v "$dir" "$bak_dir"
    fi
    # mount existing branch
    git worktree add "$dir" "$branch"
    has_worktree[$worktree]=1
  fi

  if [ -e "$bak_dir" ]; then
    echo "moving files from existing worktree dir ${bak_dir@Q} to ${dir@Q}"
    shopt -s dotglob
    for db_path_1 in "$bak_dir"/*xxx.db; do
      db_name=$(basename "$db_path_1")
      db_path_2="$dir/$db_name"
      if [ -e "$db_path_2" ]; then
        sum_1=$(md5sum "$db_path_1" | head -c32)
        sum_2=$(md5sum "$db_path_2" | head -c32)
        if [ "$sum_1" = "$sum_2" ]; then
          echo "removing duplicate file $db_path_1"
          rm "$db_path_1"
        else
          echo "FIXME keeping duplicate file $db_path_1 with different content than $db_path_2"
        fi
        continue
      fi
      mv "$db_path_1" "$db_path_2"
    done
    rmdir "$bak_dir" || true
  fi

  # undo previous "git add"
  git -C $dir restore --staged .

  # add one shard per commit to allow incremental "git push"
  while read shard_path; do
    echo "shard_path $shard_path"
    shard_name=$(basename $shard_path .db)
    echo "shard_name $shard_name"
    #continue # dry run
    git -C $dir add "$shard_path"
    git -C $dir "${cfg[@]}" commit -m "add shard $shard_name"
    sleep 1
  done < <(
    # note: temporary files are ignored by .gitignore
    git -C $dir status --untracked-files=all --porcelain=2 | grep '^? ' | cut -c3-
  )

done
