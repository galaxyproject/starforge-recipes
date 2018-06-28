#!/bin/bash
set -e
set -xv

. $HOME/venv/bin/activate

while read meta; do
    _f=${meta#wheels/}
    wheel=${_f%%/*}
    echo "Building '$wheel' wheel from $meta"
    case $TRAVIS_OS_NAME in
        osx)
            starforge --config-file="starforge.yml" --debug bdist_wheel --wheels-config="$meta" --image=ci/${TRAVIS_OS_NAME}-${PY} --fetch-srcs $wheel
            ;;
        linux)
            starforge --config-file="starforge.yml" --debug wheel --wheels-config="$meta" --image=ci/${TRAVIS_OS_NAME}-${PY}:x86_64 --no-sdist $wheel
            starforge --config-file="starforge.yml" --debug wheel --wheels-config="$meta" --image=ci/${TRAVIS_OS_NAME}-${PY}:i686 --no-sdist $wheel
            ;;
    esac
done < __wheels.txt
