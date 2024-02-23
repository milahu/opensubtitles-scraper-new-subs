#!/usr/bin/env bash

workdir="$PWD"

cd "$(dirname "$0")"

last_shard_id=
first_shard_id=
num_shards_missing=0
total_num_files_missing=0
missing_files_list=""

# filter
# opensubtitles.org.dump.9180519.to.9521948.by.lang.2023.04.26
min_shard_id=9521

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

        num_files_missing=$(( 1000 - $(ls -U ../new-subs/$missing_shard_id* 2>/dev/null | wc -l) ))

        echo "missing shard $missing_shard_id: $num_files_missing of 1000 files are missing"

        if ((num_files_missing <= 10)); then
          # list missing files
          last_zip_id=$((${missing_shard_id}000 - 1))
          while read zip_path; do
            zip_id=${zip_path##*/}
            zip_id=${zip_id%%.*}
            #echo "$zip_id $zip_path"
            if ((zip_id - last_zip_id != 1)); then
              for missing_zip_id in $( seq $((last_zip_id + 1)) $((zip_id - 1)) ); do
                #echo "  - $missing_zip_id"
                echo "  missing file $missing_zip_id"
                #num_files_missing=$((num_files_missing + 1))
                missing_files_list+="$missing_zip_id"$'\n'
              done
            fi
            last_zip_id=$zip_id
          done < <(ls -U ../new-subs/$missing_shard_id* 2>/dev/null)
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

done < <(find shards/ -name '*.db' | LANG=C sort)



echo "first shard_id: $first_shard_id"
echo "last shard_id: $last_shard_id"
echo "missing shards: $num_shards_missing"
echo "missing files: $total_num_files_missing"

missing_files_path="missing_files.$(date -Is).txt"
echo "writing $missing_files_path"
echo -n "$missing_files_list" >"$workdir/$missing_files_path"
echo "TODO"
echo "  mv $missing_files_path missing_numbers.txt"
echo "... so fetch-subs.py can fetch the missing files"
