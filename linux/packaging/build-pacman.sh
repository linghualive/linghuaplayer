#!/bin/bash
set -e

VERSION="$1"

pacman -Sy --noconfirm base-devel

# Copy pre-built files to accessible location
cp -r /workspace/build/linux/x64/release/bundle /tmp/bundle
cp /workspace/linux/packaging/flamekit.desktop /tmp/flamekit.desktop
cp /workspace/logo.png /tmp/flamekit.png
chmod -R a+rX /tmp/bundle /tmp/flamekit.desktop /tmp/flamekit.png

# Create build user (makepkg refuses to run as root)
useradd -m builder

BUILD_DIR="/home/builder/build"
mkdir -p "$BUILD_DIR"

# Write PKGBUILD (single-quoted heredoc to keep $pkgdir literal)
cat > "$BUILD_DIR/PKGBUILD" << 'PKGEOF'
pkgname=flamekit
pkgrel=1
pkgdesc='Multi-source Music Player'
arch=('x86_64')
url='https://github.com/linghualive/linghuaplayer'
license=('GPL-3.0-or-later')
depends=('gtk3' 'mpv')
options=('!strip' '!debug')

package() {
  install -dm755 "$pkgdir/usr/lib/flamekit"
  cp -r /tmp/bundle/* "$pkgdir/usr/lib/flamekit/"

  install -dm755 "$pkgdir/usr/bin"
  printf '#!/bin/bash\nexec /usr/lib/flamekit/flamekit "$@"\n' > "$pkgdir/usr/bin/flamekit"
  chmod 755 "$pkgdir/usr/bin/flamekit"

  install -Dm644 /tmp/flamekit.desktop "$pkgdir/usr/share/applications/flamekit.desktop"
  install -Dm644 /tmp/flamekit.png "$pkgdir/usr/share/icons/hicolor/256x256/apps/flamekit.png"
}
PKGEOF

# Inject version into PKGBUILD
sed -i "2i pkgver=$VERSION" "$BUILD_DIR/PKGBUILD"

chown -R builder:builder "$BUILD_DIR"
cd "$BUILD_DIR"
su builder -c 'makepkg -d'

cp "$BUILD_DIR/flamekit-${VERSION}-1-x86_64.pkg.tar.zst" /workspace/flamekit-linux-x64.pkg.tar.zst
