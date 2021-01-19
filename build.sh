#!/bin/bash
set -euo pipefail

if [ -z "${GITHUB_WORKSPACE:-}" ]; then
    cd $(dirname $0)
    GITHUB_WORKSPACE=$PWD
fi

: ${STARFORGE:="git+https://github.com/galaxyproject/starforge#egg=starforge"}
: ${STARFORGE_CMD:="starforge --config-file=starforge.yml"}
: ${STARFORGE_VENV:="${GITHUB_WORKSPACE}/venv"}
: ${WHEEL_BUILDER_TYPE:="c-extension"}
: ${DELOCATE:="git+https://github.com/natefoo/delocate@top-level-fix-squash#egg=delocate"}
: ${OS_NAME:=$(uname -s)}


function setup_build() {
    [ ! -d "$STARFORGE_VENV" ] && python3 -m venv "$STARFORGE_VENV"
    . "${STARFORGE_VENV}/bin/activate"
    pip install "$STARFORGE"
}


function run_build() {
    . "${STARFORGE_VENV}/bin/activate"

    PY=$(python3 -c 'import sys; print(".".join(map(str, sys.version_info[:2])))')

    BUILD_WHEEL_METAS=()
    for meta in $(cat "${GITHUB_WORKSPACE}/wheel_metas.txt"); do
        _f=${meta#wheels/} ; wheel=${_f%%/*}
        wheel_type=$($STARFORGE_CMD wheel_type --wheels-config="$meta" "$wheel") || exit $?
        if [ "$wheel_type" == "$WHEEL_BUILDER_TYPE" ]; then
            BUILD_WHEEL_METAS+=("$meta")
        else
            echo "Builder for '$WHEEL_BUILDER_TYPE' skipping wheel '$wheel' of type '$wheel_type'"
        fi
    done

    if [ ${#BUILD_WHEEL_METAS[@]} -eq 0 ]; then
        echo "No wheel changes for builder '$WHEEL_BUILDER_TYPE', terminating"
        exit 0
    fi

    if [ "$WHEEL_BUILDER_TYPE" == 'c-extension' ]; then
        case "$OS_NAME" in
            Darwin)
                STARFORGE_IMAGE_ARGS="--image=ci/osx-${PY}"
                pip install "$DELOCATE" "${STARFORGE}[lzma]"
                pip install pyopenssl ndg-httpsclient pyasn1
                ;;
            Linux)
                STARFORGE_IMAGE_ARGS="--image=ci/linux-${PY}:x86_64 --image=ci/linux-${PY}:i686"
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
    else
        STARFORGE_IMAGE_ARGS="--image=ci/linux-${PY}:${WHEEL_BUILDER_TYPE}"
    fi

    for meta in "${BUILD_WHEEL_METAS[@]}"; do
        _f=${meta#wheels/} ; wheel=${_f%%/*}
        echo "Building '$wheel' wheel from config: $meta"
        $STARFORGE_CMD --debug wheel --wheels-config="$meta" --wheel-dir=wheelhouse $STARFORGE_IMAGE_ARGS "$wheel"; STARFORGE_EXIT_CODE=$?
        if [ "$STARFORGE_EXIT_CODE" -eq 0 ]; then
            echo "Testing '$wheel' wheel"
            $STARFORGE_CMD --debug test_wheel --wheels-config="$meta" --wheel-dir=wheelhouse $STARFORGE_IMAGE_ARGS "$wheel" || exit $?
        elif [ "$STARFORGE_EXIT_CODE" -eq 1 ]; then
            echo "Building '$wheel' wheel failed"
            exit 1
        else
            # why do we not just use -ne 0? what is the significance of this?
            echo "\`starforge wheel\` exited with code '$STARFORGE_EXIT_CODE', skipping wheel test"
        fi
    done
}


if [ ! -f "${GITHUB_WORKSPACE}/wheel_metas.txt" ]; then
    echo "No wheel_metas.txt, exiting"
    exit 1
fi


case "${1:-}" in
    setup)
        setup_build
        ;;
    build)
        run_build
        ;;
    '')
        setup_build
        run_build
        ;;
    *)
        echo "usage: build.sh [setup|build]" >&2
        exit 1
        ;;
esac
