#!/usr/bin/env bash

# clone all git branches
# based on https://stackoverflow.com/a/7216269/10440128

src=https://github.com/milahu/opensubtitles-scraper-new-subs
main_branch=main

dst=${src##*/}
git clone --mirror $src $dst/.git
cd $dst
git config --bool core.bare false
git checkout $main_branch
