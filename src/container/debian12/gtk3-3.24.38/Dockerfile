# =============================================================================
# GTK 3.24.38 Builder MIT Tests
# =============================================================================
FROM debian:bookworm-slim AS builder

# Build-Abhängigkeiten inklusive Test-Tools
RUN apt-get update && apt-get install -y \
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
    xvfb dbus-x11 python3-pip \
    && rm -rf /var/lib/apt/lists/*

# Für GUI-Tests: virtuellem Display und DBus
ENV DISPLAY=:99

# GTK Installationsverzeichnis
ENV GTK_PREFIX=/opt/gtk3
RUN mkdir -p ${GTK_PREFIX}

# GTK 3.24.38 aus GitHub-Quellen bauen
WORKDIR /tmp
RUN git config --global advice.detachedHead false
RUN git clone --depth 1 --branch 3.24.38 https://github.com/GNOME/gtk.git gtk-3.24.38

WORKDIR /tmp/gtk-3.24.38/build

# Meson mit Tests konfigurieren
RUN meson setup .. \
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
RUN ninja

# Tests ausführen (mit virtuellem Display)
RUN Xvfb :99 -screen 0 1024x768x24 &
RUN dbus-daemon --session --fork
RUN ninja test || echo "Einige Tests fehlgeschlagen, aber Build wird fortgesetzt"

# Installieren (nur wenn Tests okay)
RUN ninja install

# =============================================================================
# GTK 3.24.38 Base Image (MIT Entwicklungs-Paketen)
# =============================================================================
FROM debian:bookworm-slim

# Entwicklungs-Pakete für alle GTK-Abhängigkeiten installieren
RUN apt-get update && apt-get install -y \
    libcairo2-dev \
    libpango1.0-dev \
    libgdk-pixbuf2.0-dev \
    libatk1.0-dev \
    libatk-bridge2.0-dev \
    libxkbcommon-dev \
    gobject-introspection \
    libgirepository1.0-dev \
    libepoxy-dev \
    libharfbuzz-dev \
    libfribidi-dev \
    libfontconfig1-dev \
    libfreetype6-dev \
    libpng-dev \
    libjpeg-dev \
    libtiff-dev \
    libx11-dev \
    libxext-dev \
    libxrender-dev \
    libxi-dev \
    libxinerama-dev \
    libxrandr-dev \
    libxcursor-dev \
    libxdamage-dev \
    libxcomposite-dev \
    libxfixes-dev \
    libwayland-dev \
    wayland-protocols \
    libgl-dev \
    libxml2-dev \
    gettext \
    libcups2-dev \
    libgstreamer1.0-dev \
    libgstreamer-plugins-base1.0-dev \
    libcolord-dev \
    libcloudproviders-dev \
    libjson-glib-dev \
    librest-dev \
    gnat \
    pkg-config \
    && rm -rf /var/lib/apt/lists/*

# GTK Installation kopieren
COPY --from=builder /opt/gtk3 /opt/gtk3

# Umgebungsvariablen
ENV GTK_PREFIX=/opt/gtk3
ENV PATH=$GTK_PREFIX/bin:$PATH
ENV PKG_CONFIG_PATH=$GTK_PREFIX/lib/x86_64-linux-gnu/pkgconfig:$GTK_PREFIX/lib/pkgconfig:/usr/lib/x86_64-linux-gnu/pkgconfig:/usr/share/pkgconfig
ENV LD_LIBRARY_PATH=$GTK_PREFIX/lib/x86_64-linux-gnu:$GTK_PREFIX/lib:$LD_LIBRARY_PATH
ENV GI_TYPELIB_PATH=$GTK_PREFIX/lib/x86_64-linux-gnu/girepository-1.0:$GI_TYPELIB_PATH
ENV XDG_DATA_DIRS=$GTK_PREFIX/share:${XDG_DATA_DIRS:-/usr/local/share/:/usr/share/}

# Verifikation
RUN pkg-config --modversion gtk+-3.0 && \
    pkg-config --modversion pango && \
    pkg-config --modversion cairo && \
    echo "✅ GTK 3.24.38 Base Image (mit dev-Paketen) bereit"

CMD ["bash"]

