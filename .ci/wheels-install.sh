#!/bin/bash
set -e
set -xv

#starforge="git+https://github.com/natefoo/starforge.git@py3-wheels#egg=starforge"
#virtualenv_vers="16.0.0"
#virtualenv="https://files.pythonhosted.org/packages/33/bc/fa0b5347139cd9564f0d44ebd2b147ac97c36b2403943dbee8a25fd74012/virtualenv-16.0.0.tar.gz"

case $TRAVIS_OS_NAME in
    osx)
        case $PY in
            2.7)
                pypt=15
                ;;
            3.4)
                pypt=4
                ;;
            3.5)
                pypt=4
                ;;
            3.6)
                pypt=6
                ;;
            3.7)
                pypt=0
                ;;
        esac
        sudo ln -s /Applications/Xcode.app/Contents/Developer/Platforms/MacOSX.platform/Developer /Developer
        curl -LO https://www.python.org/ftp/python/${PY}.${pypt}/python-${PY}.${pypt}-macosx10.6.pkg
        sudo installer -pkg python-${PY}.${pypt}-macosx10.6.pkg -target /
        #curl -O "$virtualenv"
        #tar zxvf virtualenv-${virtualenv_vers}.tar.gz
        #/Library/Frameworks/Python.framework/Versions/${PY}/bin/python${PY%%.*} ./virtualenv-${virtualenv_vers}/virtualenv.py $HOME/venv
        # we need Starforge in the buildenv since the osx build uses the local execucution context, but installing it a
        # second time should be low cost since pip will have cached it
        rm -rf $STARFORGE_VENV
        virtualenv -p /Library/Frameworks/Python.framework/Versions/${PY}/bin/python${PY%%.*} $STARFORGE_VENV
        # $STARFORGE_VENV should still be activated
        #. $HOME/buildenv/bin/activate
        # pip can't upgrade itself due to TLS errors
        #curl https://bootstrap.pypa.io/get-pip.py | python
        pip install $STARFORGE
        pip install delocate
        ;;
    linux)
        #virtualenv $HOME/venv
        #$HOME/venv/bin/pip install $STARFORGE
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

set +xv
