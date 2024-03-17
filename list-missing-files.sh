#!/usr/bin/env bash

workdir="$PWD"

cd "$(dirname "$0")"

last_shard_id=
first_shard_id=
num_shards_missing=0
total_num_files_missing=0
missing_files_list=""

# filter
# opensubtitles.org.dump.9700000.to.9799999
min_shard_id=9800

last_shard_id=$min_shard_id



while read shard_path; do

  shard_id=${shard_path##*/}
  shard_id=${shard_id%xxx.db}

  ((shard_id < min_shard_id)) && continue

  if [ -z "$first_shard_id" ]; then
    first_shard_id=$shard_id
  fi

  if [ -n "$last_shard_id" ]; then
    if ((shard_id - last_shard_id != 1)); then
      num_shards_missing_here=$((shard_id - last_shard_id - 1)) # TODO?
      num_shards_missing=$((num_shards_missing + num_shards_missing_here))
      #echo "missing shards between $last_shard_id and $shard_id = $num_shards_missing_here shards are missing"
      #echo "missing shards from $((last_shard_id + 1)) to $((shard_id - 1)) = $num_shards_missing_here shards are missing"
      for missing_shard_id in $(seq $((last_shard_id + 1)) $((shard_id - 1))); do
        #echo "missing shard $missing_shard_id"
        #echo "- $missing_shard_id"

        #echo "missing files of shard $missing_shard_id ..."

        # missing files

        #echo "missing_shard_id $missing_shard_id"

        #sql_query="select IDSubtitle from subz_metadata where IDSubtitle "
        #sql_query+="between ${missing_shard_id}000 and ${missing_shard_id}999"
        #expected_shard_nums=$(sqlite3 ../subtitles_all.latest.db "$sql_query")

        expected_shard_nums=$(../subtitles_all.latest.db.get-num-range.sh "${missing_shard_id}000" "${missing_shard_id}999")

        actual_shard_nums=$(cd ../new-subs/ && ls -U $missing_shard_id* 2>/dev/null | cut -d. -f1 | sort -n)

        missing_shard_nums=$(
          diff -u0 <(echo "$actual_shard_nums") <(echo "$expected_shard_nums") |
          grep -E '^\+[0-9]' | cut -c2-
        )

        if false; then
          echo "actual_shard_nums"; echo "$actual_shard_nums" | head
          echo "expected_shard_nums"; echo "$expected_shard_nums" | head
          echo "missing_shard_nums"; echo "$missing_shard_nums" | head
        fi

        num_files_missing=$(echo "$missing_shard_nums" | wc -l)

        echo "missing shard $missing_shard_id: $num_files_missing of 1000 files are missing"

        if ((num_files_missing <= 150)); then
          missing_files_list+="$missing_shard_nums"$'\n'
        fi

        #echo "missing files of shard $missing_shard_id done"

        total_num_files_missing=$((total_num_files_missing + num_files_missing))

      done
    fi
  fi

  #echo "shard: $shard_path -- shard_id: $shard_id -- last shard_id: $last_shard_id"
  #echo "done shard $shard_id"
  #echo "+ $shard_id"

  last_shard_id=$shard_id

done < <(
  find shards/ -name '*.db' | LANG=C sort --version-sort
)



echo "first shard_id: $first_shard_id"
echo "last shard_id: $last_shard_id"
echo "missing shards: $num_shards_missing"
echo "missing files: $total_num_files_missing"

write_missing_files_list=true

if $write_missing_files_list && [ -n "$missing_files_list" ]; then
  missing_files_path="missing_files.$(date -Is).txt"
  echo "writing $missing_files_path"
  echo -n "$missing_files_list" >"$workdir/$missing_files_path"
  echo "TODO"
  echo "  mv $missing_files_path missing_numbers.txt"
  echo "... so fetch-subs.py can fetch the missing files"
fi
