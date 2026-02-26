#!/bin/bash
set -e

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
PROJECT_DIR="$( dirname "$DIR" )"

cd "$PROJECT_DIR/plugin"
rm -rf build
mkdir build
cd build
cmake -DCMAKE_INSTALL_PREFIX="$HOME/.local" -DKDE_INSTALL_QMLDIR="$HOME/.local/lib/qml" ..
make
make install
