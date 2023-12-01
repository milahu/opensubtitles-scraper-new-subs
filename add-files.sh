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

  old_name="$(basename "$file_path")"

  echo

  if ! [ -e "$file_path" ]; then
    echo "no such file: $file_path"
    continue
  fi

  echo "input file: $file_path"

  file_type="$(file -b --mime-type "$file_path")"
  case "$file_type" in
    application/zip)
      # 12345.zip

      # allow lossy filenames like 12345.zip
      # wontfix: the *.nfo files contain only a truncated version of the filename
      # because the values are truncated after 58 bytes
      # we tolerate a missing filename extension ".zip"
      # so if the zip filename is longer than 62 bytes, the zip filename is lost
      # and we have to re-download the zip file, to get the original zip filename

      #echo "found zip file: $file_path"
      nfo_filename="$(unzip -l -q -q "$file_path" | grep '\.nfo$' | awk '{ print $4 }')"
      if [ -z "$nfo_filename" ]; then
        echo "not found *.nfo file in zipfile: $file_path"
        continue
      fi
      #echo "found nfo file: $nfo_filename"
      # unpack the nfo file
      tempdir=$(mktemp -d --suffix=-new-subs-repo-add-files -p /run/user/$(id -u)/)
      unzip -q -q "$file_path" "$nfo_filename" -d "$tempdir"
      nfo_path="$tempdir/$nfo_filename"
      # parse zip filename from nfo
      maybe_zip_name="$(grep '^.  Filename       : ' "$nfo_path" | head -n1 | cut -c22-79 | tr -d ' ')"
      #echo "maybe zip name: $maybe_zip_name"
      if [[ "$maybe_zip_name" == *".zip" ]]; then
        echo "nfo: found zip name: $maybe_zip_name"
        old_name="$maybe_zip_name"
      else
        #echo "nfo: found truncated zip name: $maybe_zip_name"
        maybe_zip_basename="$(
          echo "$maybe_zip_name" |
          grep -o -E "^.*\.\([0-9]+\)\.[a-z]{3}\.[0-9]+cd\.\(([0-9]+)\)" || true
        )"
        #echo "nfo: maybe zip basename: $maybe_zip_basename"
        if [ -n "$maybe_zip_basename" ]; then
          # use a slightly truncated zip filename
          # the ".zip" extension can be truncated
          # example:
          # encounters.s01.e01.episode.1.1.(2023).hrv.1cd.(9756714).z
          old_name="$maybe_zip_basename.zip"
          echo "nfo: found zip name: $old_name"
        else
          echo "nfo: not using truncated zip filename: $maybe_zip_name"
        fi
      fi
      # cleanup
      rm -rf "$tempdir"
      ;;
    inode/x-empty)
      # 12345.not-found
      if ! echo "$old_name" | grep -q -E "^[0-9]+\.not-found$"; then
        echo "ignoring non-subtitle file: $file_path"
        continue
      fi
      ;;
    *)
      echo "ignoring non-subtitle file: $file_path"
      continue
      ;;
  esac

  if ! echo "$old_name" | grep -q -E "^([0-9]+\.(.*\.[0-9]+cd\.zip|not-found)|.*\.[0-9]+cd\.\(([0-9]+)\)\.zip)$"; then
    echo "ignoring non-subtitle file: $file_path"
    continue
  fi

  if echo "$old_name" | grep -q -E "^[0-9]+\.(.*\.[0-9]+cd\.zip|not-found)$"; then
    # filename already has the "new" format
    # = num was already moved from end to start
    new_name="$old_name"
  else
    # move num from end to start
    # a: some.movie.(2023).eng.1cd.(12345).zip
    # b: 12345.some.movie.(2023).eng.1cd.zip
    new_name="$(echo "$old_name" | sed -E 's/(.*\.[0-9]+cd)\.\(([0-9]+)\)\.zip$/\2.\1.zip/')"
    if [[ "$old_name" == "$new_name" ]]; then
      echo "failed to fix filename: $file_path"
      continue
    fi
  fi

  num=$(echo "$new_name" | cut -d. -f1)

  if grep -q "^$num." files.txt; then
    echo "output file exists: $new_name"
    mv -v "$file_path" trash/ || rm -v "$file_path"
    continue
  fi

  if ! echo "$new_name" | grep -q -E "^[0-9]+\.(not-found)$"; then

    echo "adding file: $file_path"

    worktree_path="nums/$num"

    if [ -d "$worktree_path" ]; then
      echo "removing old worktree $worktree_path"
      git worktree remove --force "$worktree_path"
      rm -rf "$worktree_path"
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
    git worktree remove --force "$worktree_path"
    rm -rf "$worktree_path"

  fi

  echo "adding file to index: $file_path"
  echo "$new_name" >>files.txt
  git add files.txt
  git commit --quiet -m "files.txt: add $num"

  mv -v "$file_path" trash/ || rm -v "$file_path"

  files_added=true

done



#if $files_added; then
if false; then

  echo pushing all branches
  #git push --all --force
  git push --all

fi
