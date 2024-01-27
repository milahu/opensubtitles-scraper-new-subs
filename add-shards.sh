#!/usr/bin/env bash

cd "$(dirname "$0")"

for db in ../new-subs-shards/shards/*.db
do

  n=$(basename "$db")
  s=$(echo "$n" | sed -E 's/^([0-9]*)([0-9]{2})xxx\.db$/\1xxxxx/')

  if [ "$s" = "xxxxx" ]; then s="0xxxxx"; fi

  if ! [ -e "shards/$s" ]; then mkdir -v -p "shards/$s"; fi

  dst="shards/$s/$n"

  if ! [ -e "$dst" ]; then ln -v "$db" "$dst"; fi

done
