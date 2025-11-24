#!/bin/bash

set -euo pipefail

get_script_dir() {
    # Deine bestehende Funktion bleibt gleich
    local SOURCE_PATH="${BASH_SOURCE[0]}"
    local SYMLINK_DIR
    local SCRIPT_DIR
    while [ -L "$SOURCE_PATH" ]; do
        SYMLINK_DIR="$( cd -P "$( dirname "$SOURCE_PATH" )" >/dev/null 2>&1 && pwd )"
        SOURCE_PATH="$(readlink "$SOURCE_PATH")"
        if [[ $SOURCE_PATH != /* ]]; then
            SOURCE_PATH=$SYMLINK_DIR/$SOURCE_PATH
        fi
    done
    SCRIPT_DIR="$(cd -P "$( dirname "$SOURCE_PATH" )" >/dev/null 2>&1 && pwd)"
    echo "$SCRIPT_DIR"
}

### ============================================================ ###
### ======================== M A I N =========================== ###
### ============================================================ ###

SCRIPT_DIR=$(get_script_dir)
cd "$SCRIPT_DIR/../../../"
ROOT_DIR=$(pwd)

echo " + Root is $ROOT_DIR"

PY_VERSION=3.14

unset PYTHONPATH
unset PYTHONHOME

## Install dependencies:
sudo apt install -y \
    git build-essential gnat meson ninja-build pkg-config \
    libcairo2-dev libpango1.0-dev libgdk-pixbuf-2.0-dev libatk1.0-dev \
    libatk-bridge2.0-dev libxkbcommon-dev gobject-introspection \
    libgirepository1.0-dev libepoxy-dev libharfbuzz-dev libfribidi-dev \
    libfontconfig1-dev libfreetype6-dev libpng-dev libjpeg-dev libtiff-dev \
    libx11-dev libxext-dev libxrender-dev libxi-dev libxinerama-dev \
    libxrandr-dev libxcursor-dev libxdamage-dev libxcomposite-dev \
    libxfixes-dev libwayland-dev wayland-protocols libgl-dev libxml2-dev \
    gettext libcups2-dev libgstreamer1.0-dev libgstreamer-plugins-base1.0-dev \
    libcolord-dev libcloudproviders-dev libjson-glib-dev librest-dev sassc \
    xvfb \
    libssl-dev zlib1g-dev libbz2-dev libreadline-dev libsqlite3-dev \
    libncursesw5-dev tk-dev libgdbm-dev liblzma-dev libffi-dev

# Python Installationsverzeichnis
PY_PREFIX="$ROOT_DIR/opt/python3"
rm -rf "$PY_PREFIX"
mkdir -p "$PY_PREFIX"

## Python aus GitHub-Quellen bauen
rm -rf "$ROOT_DIR/tmp/"
mkdir -p "$ROOT_DIR/tmp"
cd "$ROOT_DIR/tmp"
git config --global advice.detachedHead false
git clone --depth 1 --branch "$PY_VERSION" https://github.com/python/cpython python3

cd python3

# Build konfigurieren - HIER KORRIGIERT: PY_PREFIX statt PY_PEFIX
./configure --prefix="$PY_PREFIX" --enable-optimizations --enable-shared

echo "### ====================================================="
echo "### ===================== Bauen ========================="
echo "### ====================================================="
make -j$(nproc)

echo "### ====================================================="
echo "### ===================== Testen ========================"
echo "### ====================================================="
#make test || echo "!!! Some tests failed - Continue build !!!"

export PATH="$PY_PREFIX/bin:$PATH"
echo "### ====================================================="
echo "### ===================== Installieren==================="
echo "### ====================================================="
make install

echo "### ====================================================="
echo "### ===================== Verifikation =================="
echo "### ====================================================="
export PATH="$PY_PREFIX/bin:$PATH"
export PKG_CONFIG_PATH="$PY_PREFIX/lib/x86_64-linux-gnu/pkgconfig:$PY_PREFIX/lib/pkgconfig"
export LD_LIBRARY_PATH="$PY_PREFIX/lib/x86_64-linux-gnu:$PY_PREFIX/lib"
export GI_TYPELIB_PATH="$PY_PREFIX/lib/x86_64-linux-gnu/girepository-1.0"
export XDG_DATA_DIRS="$PY_PREFIX/share"
sudo ldconfig

# Verifikation
python3 --version && \
    pip3 --version && \
    echo -n "Modversion: " && pkg-config --modversion python3 && \
    echo "✅ Python $PY_VERSION build successful" || \
    echo "!!!!! Build error !!!!!"
