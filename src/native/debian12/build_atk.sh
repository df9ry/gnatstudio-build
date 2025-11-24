#!/bin/bash

get_script_dir()
{
    local SOURCE_PATH="${BASH_SOURCE[0]}"
    local SYMLINK_DIR
    local SCRIPT_DIR
    # Resolve symlinks recursively
    while [ -L "$SOURCE_PATH" ]; do
        # Get symlink directory
        SYMLINK_DIR="$( cd -P "$( dirname "$SOURCE_PATH" )" >/dev/null 2>&1 && pwd )"
        # Resolve symlink target (relative or absolute)
        SOURCE_PATH="$(readlink "$SOURCE_PATH")"
        # Check if candidate path is relative or absolute
        if [[ $SOURCE_PATH != /* ]]; then
            # Candidate path is relative, resolve to full path
            SOURCE_PATH=$SYMLINK_DIR/$SOURCE_PATH
        fi
    done
    # Get final script directory path from fully resolved source path
    SCRIPT_DIR="$(cd -P "$( dirname "$SOURCE_PATH" )" >/dev/null 2>&1 && pwd)"
    echo "$SCRIPT_DIR"
}

### ============================================================ ###
### ======================== M A I N =========================== ###
### ============================================================ ###

SCRIPT_DIR=$(get_script_dir)
cd $SCRIPT_DIR/../../../
ROOT_DIR=$(pwd)

echo " + Root is $ROOT_DIR"

## Install dependencies:
sudo apt install -y \
    git build-essential gnat meson ninja-build pkg-config \
    libglib2.0-dev libglib2.0-dev-bin

# GTK Installationsverzeichnis
export GTK_PREFIX=$ROOT_DIR/opt/gtk3
export PATH=$GTK_PREFIX/bin:$PATH
export LD_LIBRARY_PATH=$GTK_PREFIX/lib/x86_64-linux-gnu:$GTK_PREFIX/lib:$LD_LIBRARY_PATH
export PKG_CONFIG_PATH=$GTK_PREFIX/lib/x86_64-linux-gnu/pkgconfig:$GTK_PREFIX/lib/pkgconfig:/usr/lib/x86_64-linux-gnu/pkgconfig:/usr/share/pkgconfig
export GI_TYPELIB_PATH=$GTK_PREFIX/lib/x86_64-linux-gnu/girepository-1.0:$GI_TYPELIB_PATH
export XDG_DATA_DIRS=$GTK_PREFIX/share:${XDG_DATA_DIRS:-/usr/local/share/:/usr/share/}
sudo ldconfig

## Aus Quellen bauen
rm -rf $ROOT_DIR/tmp/
mkdir -p $ROOT_DIR/tmp
cd $ROOT_DIR/tmp
git config --global advice.detachedHead false
git clone https://gitlab.gnome.org/Archive/atk

cd $ROOT_DIR/tmp/atk

meson setup --prefix=$GTK_PREFIX _build .
ninja -C _build
ninja -C _build install

# Verifikation
echo -n "Modversion: " && \
    pkg-config --modversion atk && \
    echo "✅ ATK Build ready"

