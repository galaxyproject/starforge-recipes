#!/bin/bash
set -e
#set -xv

echo "Detecting changes to wheels/..."

if ! git diff --quiet $TRAVIS_COMMIT_RANGE -- 2>/dev/null; then
    git remote set-branches --add origin master
    git fetch
    TRAVIS_COMMIT_RANGE=origin/master...
fi
git diff --color=never --name-status $TRAVIS_COMMIT_RANGE -- wheels/

while read op path; do
    case "${path##*/}" in
        meta.yml)
            ;;
        *)
            continue
            ;;
    esac
    case "$op" in
        A|M)
            echo "$op $path"
            echo "${path}" >> __wheels.txt
            ;;
    esac
done < <(git diff --color=never --name-status $TRAVIS_COMMIT_RANGE -- wheels/)
