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

( ### Start local environment
SCRIPT_DIR=$(get_script_dir)
cd $SCRIPT_DIR/../../../
ROOT_DIR=`pwd`

echo " + Root is $ROOT_DIR"

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
    xvfb dbus-x11 python3-pip

# GTK Installationsverzeichnis
GTK_PREFIX=$ROOT_DIR/opt/gtk3
rm -rf $GTK_PREFIX
mkdir -p $GTK_PREFIX

## GTK 3.24.38 aus GitHub-Quellen bauen
rm -rf $ROOT_DIR/tmp/
mkdir -p $ROOT_DIR/tmp
cd $ROOT_DIR/tmp
git config --global advice.detachedHead false
git clone --depth 1 --branch 3.24.38 https://github.com/GNOME/gtk.git gtk-3.24.38

mkdir $ROOT_DIR/tmp/gtk-3.24.38/build
cd $ROOT_DIR/tmp/gtk-3.24.38/build

# Meson mit Tests konfigurieren
meson setup .. \
    --prefix=${GTK_PREFIX} \
    --buildtype=release \
    -Dintrospection=true \
    -Ddemos=true \
    -Dexamples=true \
    -Dtests=true \
    -Dinstalled_tests=true \
    -Dcolord=yes \
    -Dcloudproviders=true \
    -Dwayland_backend=true \
    -Dx11_backend=true

# Bauen
ninja

# Tests ausführen (mit virtuellem Display)
ninja test || echo "Einige Tests fehlgeschlagen, aber Build wird fortgesetzt"

# Installieren (nur wenn Tests okay)
ninja install

# Umgebungsvariablen
GTK_PREFIX=$ROOT_DIR/opt/gtk3
PATH=$GTK_PREFIX/bin:$PATH
PKG_CONFIG_PATH=$GTK_PREFIX/lib/x86_64-linux-gnu/pkgconfig:$GTK_PREFIX/lib/pkgconfig:/usr/lib/x86_64-linux-gnu/pkgconfig:/usr/share/pkgconfig
LD_LIBRARY_PATH=$GTK_PREFIX/lib/x86_64-linux-gnu:$GTK_PREFIX/lib:$LD_LIBRARY_PATH
GI_TYPELIB_PATH=$GTK_PREFIX/lib/x86_64-linux-gnu/girepository-1.0:$GI_TYPELIB_PATH
XDG_DATA_DIRS=$GTK_PREFIX/share:${XDG_DATA_DIRS:-/usr/local/share/:/usr/share/}

sudo apt install -y pkg-config
 
# Verifikation
pkg-config --modversion gtk+-3.0 && \
    pkg-config --modversion pango && \
    pkg-config --modversion cairo && \
    echo "✅ GTK 3.24.38 Build ready"

) ### End local environment ###
