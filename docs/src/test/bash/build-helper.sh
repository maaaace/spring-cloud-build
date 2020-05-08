#!/bin/bash

[[ -z $DEBUG ]] || set -o xtrace

set -o errexit
set -o errtrace
set -o nounset
set -o pipefail

ROOT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
ROOT_DIR="${ROOT_DIR}/../../.."
echo "Root directory is [${ROOT_DIR}]"

function usage {
    echo "usage: $0: <download-shellcheck|run-shellcheck|download-bats|run-bats|initialize-submodules>"
    exit 1
}

if [[ $# -ne 1 ]]; then
    usage
fi

SHELLCHECK_VERSION="v0.7.0"
ARCH="x86_64"
if [ "$(uname -m)" == aarch64 ]; then
    ARCH="aarch64"
fi
SHELLCHECK_BIN="${ROOT_DIR}/../target/shellcheck-${SHELLCHECK_VERSION}/shellcheck"

case $1 in
    download-shellcheck)
        if [[ "${OSTYPE}" == linux* && ! -z "${SHELLCHECK_BIN}" ]]; then
            SHELLCHECK_ARCHIVE="shellcheck-${SHELLCHECK_VERSION}.linux.${ARCH}.tar.xz"
            if [[ -x "${ROOT_DIR}/../target/shellcheck-${SHELLCHECK_VERSION}/shellcheck" ]]; then
                echo "shellcheck already downloaded - skipping..."
                exit 0
            fi
            wget -P "${ROOT_DIR}/../target/" \
                "https://storage.googleapis.com/shellcheck/${SHELLCHECK_ARCHIVE}"
            pushd "${ROOT_DIR}/../target/"
            tar xvf "${SHELLCHECK_ARCHIVE}"
            rm -vf -- "${SHELLCHECK_ARCHIVE}"
            popd
        else
            echo "It seems that automatic installation is not supported on your platform."
            echo "Please install shellcheck manually:"
            echo "    https://github.com/koalaman/shellcheck#installing"
            exit 1
        fi
        ;;
    run-shellcheck)
            echo "Running shellcheck"
            "${SHELLCHECK_BIN}" "${ROOT_DIR}"/src/main/asciidoc/*.sh
            echo "Shellcheck passed sucessfully!"
        ;;
    download-bats)
        if [[ -x "${ROOT_DIR}/../target/bats/bin/bats" ]]; then
            echo "bats already downloaded - skipping..."
            exit 0
        fi
        git clone https://github.com/bats-core/bats-core.git "${ROOT_DIR}/../target/bats"
        ;;
    run-bats)
            echo "Running bats"
            SHELLCHECK_BIN="${ROOT_DIR}/../target/bats/bin/bats"
            "${SHELLCHECK_BIN}" "${ROOT_DIR}"/src/test/bats
            echo "Bats passed sucesfully!"
        ;;
    initialize-submodules)
        files="$( ls "${ROOT_DIR}/src/test/bats/test_helper/bats-assert/" || echo "" )"
        pushd "${ROOT_DIR}/../"
            if [ ! -z "${files}" ]; then
                echo "Submodules already initialized";
                git submodule foreach git pull origin master || echo "Failed to pull - continuing the script"
            else
                echo "Initilizing submodules"
                git submodule init
                git submodule update
                git submodule foreach git pull origin master || echo "Failed to pull - continuing the script"
            fi
        popd
        ;;
    *)
        usage
        ;;
esac