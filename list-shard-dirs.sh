#!/usr/bin/env bash

cd "$(dirname "$0")"

for dir in shards/*; do
  dir_id=${dir#*/}
  dir_id=${dir_id%xxxxx}
  num_shards=$(ls $dir/*.db | wc -l)
  num_files=$(ls -U ../new-subs | grep "^$dir_id" | wc -l)
  num_shards_todo=$(echo "$num_files" 1000 | awk '{ print $1 / $2 }')
  done_percent=$(echo "$num_shards" "$num_shards_todo" | awk '{ print int($1 + $2) }')
  printf "%s %3d + %6.3f = %3d%%\n" "$dir" "$num_shards" "$num_shards_todo" "$done_percent"
done
