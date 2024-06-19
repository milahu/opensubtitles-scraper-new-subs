#!/usr/bin/env bash

set -eux

src=https://github.com/milahu/opensubtitles-scraper-new-subs
dst=$HOME/src/milahu/opensubtitles-scraper-new-subs

# 3 minutes
# shallow clone takes 1 minute
max_pull_time=180

if ! timeout $max_pull_time git -C "$dst" pull; then
  echo "timeout on git pull. falling back to a fresh shallow clone"
  mv -v "$dst" "$dst".bak.$(date +%Y-%m-%dT%H-%M-%S%z)
  time git clone --depth=1 "$src" "$dst"
fi
