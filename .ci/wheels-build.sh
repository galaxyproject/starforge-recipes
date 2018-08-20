#!/bin/bash
set -e
set -xv

. $HOME/venv/bin/activate

case $TRAVIS_OS_NAME in
    osx)
        images=(ci/${TRAVIS_OS_NAME}-${PY})
        ;;
    linux)
        images=(ci/${TRAVIS_OS_NAME}-${PY}:x86_64 ci/${TRAVIS_OS_NAME}-${PY}:i686)
        ;;
esac

while read meta; do
    _f=${meta#wheels/}
    wheel=${_f%%/*}
    for image in ${images[@]}; do
        echo "Building '$wheel' wheel on image '$image' from $meta"
        starforge --config-file="starforge.yml" --debug bdist_wheel --wheels-config="$meta" --image="$image" --fetch-srcs "$wheel"
        echo "Testing '$wheel' wheel"
        starforge --config-file="starforge.yml" --debug test_wheel --wheels-config="$meta" --image="$image" "$wheel"
    done
done < __wheels.txt
