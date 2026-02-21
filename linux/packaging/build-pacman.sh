#!/bin/bash
set -e

VERSION="$1"

pacman -Sy --noconfirm zstd

STAGE=/tmp/pkg
mkdir -p "$STAGE/usr/lib/flamekit"
mkdir -p "$STAGE/usr/bin"
mkdir -p "$STAGE/usr/share/applications"
mkdir -p "$STAGE/usr/share/icons/hicolor/256x256/apps"

cp -r /workspace/build/linux/x64/release/bundle/* "$STAGE/usr/lib/flamekit/"

printf '#!/bin/bash\nexec /usr/lib/flamekit/flamekit "$@"\n' > "$STAGE/usr/bin/flamekit"
chmod 755 "$STAGE/usr/bin/flamekit"

cp /workspace/linux/packaging/flamekit.desktop "$STAGE/usr/share/applications/"
cp /workspace/logo.png "$STAGE/usr/share/icons/hicolor/256x256/apps/flamekit.png"

SIZE=$(du -sb "$STAGE/usr" | awk '{print $1}')

cat > "$STAGE/.PKGINFO" << EOF
pkgname = flamekit
pkgver = ${VERSION}-1
pkgdesc = Multi-source Music Player
url = https://github.com/linghualive/linghuaplayer
builddate = $(date +%s)
packager = linghualive <linghualive@users.noreply.github.com>
size = $SIZE
arch = x86_64
depend = gtk3
depend = mpv
EOF

cd "$STAGE"
tar cf - .PKGINFO usr | zstd -o /workspace/flamekit-linux-x64.pkg.tar.zst
