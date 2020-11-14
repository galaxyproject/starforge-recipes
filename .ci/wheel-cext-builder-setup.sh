#!/bin/bash
set -e
set -x

case $TRAVIS_OS_NAME in
    osx)
        # See https://www.python.org/downloads/mac-osx/ and https://www.python.org/ftp/python/
        case $PY in
            3.6)
                pypt=8
                macos_version=10.6
                ;;
            3.7)
                pypt=9
                macos_version=10.9
                ;;
            3.8)
                pypt=6
                macos_version=10.9
                ;;
            3.9)
                pypt=0
                macos_version=10.9
                ;;
        esac
        sudo ln -s /Applications/Xcode.app/Contents/Developer/Platforms/MacOSX.platform/Developer /Developer
        curl -LO https://www.python.org/ftp/python/${PY}.${pypt}/python-${PY}.${pypt}-macosx${macos_version}.pkg
        sudo installer -pkg python-${PY}.${pypt}-macosx${macos_version}.pkg -target /
        # we need Starforge in the buildenv since the osx build uses the local execution context, but installing it a
        # second time should be low cost since pip will have cached it
        rm -rf $STARFORGE_VENV
        virtualenv -p /Library/Frameworks/Python.framework/Versions/${PY}/bin/python${PY%%.*} $STARFORGE_VENV
        # $STARFORGE_VENV should still be activated
        #. $HOME/buildenv/bin/activate
        pip install "$DELOCATE" "${STARFORGE}[lzma]"
        pip install pyopenssl ndg-httpsclient pyasn1
        ;;
    linux)
        for arch in x86_64 i686; do
            image=quay.io/pypa/manylinux1_$arch
            docker pull $image
            case $arch in
                i686)
                    linux32=/usr/bin/linux32
                    entrypoint="ENTRYPOINT [\"${linux32}\"]"
                    ;;
                x86_64)
                    linux32=
                    entrypoint=
                    ;;
            esac
            sed -e "s%ARCH%${arch}%g" -e "s%STARFORGE%${STARFORGE}%g" -e "s%LINUX32%${linux32}%g" \
                -e "s%ENTRYPOINT%${entrypoint}%g" .ci/Dockerfile > .ci/Dockerfile.$arch
            echo ".ci/Dockerfile.$arch contains:"
            cat .ci/Dockerfile.$arch
            docker build -t manylinux1:$arch -f .ci/Dockerfile.$arch .
        done
        ;;
esac
