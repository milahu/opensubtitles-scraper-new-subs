# opensubtitles-scraper-new-subs

temporary files created by
[opensubtitles-scraper](https://github.com/milahu/opensubtitles-scraper)

## why

these temporary files are useful,
if you want to maximize the number of subtitles in your app

this way, you get more subtitles than using only the
[releases](https://github.com/milahu/opensubtitles-scraper/tree/main/release)

## git clone

to clone all git branches, run [git-clone.sh](git-clone.sh)

## git pull

to pull all git branches, run [git-pull.sh](git-pull.sh)

## git worktree add

to mount all git branches, run [mount-branches.sh](mount-branches.sh)

## frequency

with 1 VIP account at opensubtitles.org i can

- download 1000 subtitles per day
- publish 1 shard per day in this repo
- publish 1 release every 100 days

## releases

each release consists of 100 shards: 00 to 99

once all shards of a release are complete,
a new release is created by
[opensubtitles-scraper/shards2release.py](https://github.com/milahu/opensubtitles-scraper/blob/main/shards2release.py)
and on the next release, the shards are removed from this repo

all releases are distributed over bittorrent, see
[opensubtitles-scraper/release/](https://github.com/milahu/opensubtitles-scraper/tree/main/release)

## git branches

<details>
<summary>
before 2024-11-24
</summary>
<blockquote>

before 2024-11-24,
shards are stored in the main branch

example: shards 10200xxx to 10299xxx are stored in ./shards/102xxxxx/

problem:
this requires rewriting the git history on every third release
to keep this repo below 5GB (github soft limit).
(each release has about 1.5GB.)
but rewriting the git history is not pretty,
it makes `git pull` less efficient

</blockquote>
</details>

since 2024-11-24,
shards are stored in different git branches, one branch per release

example: shards 10200xxx to 10299xxx are stored in the git branch shards-102xxxxx

this makes it much easier to remove old files:
just remove the git branch

i must remove old git branches
to keep this repo below 5GB (github soft limit).
(each release has about 1.5GB)
