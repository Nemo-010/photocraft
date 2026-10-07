#!/bin/sh
# Build the Anylinux AppImage from the Linux tarball that packaging/linux/package.sh writes.
#
# Runs in the pkgforge Arch container (the `appimage` job in .github/workflows/release.yml):
# quick-sharun deploys the runtime libraries from the build host, so this only works on Arch,
# with the application installed under /usr.
#
# Usage: packaging/linux/appimage.sh <photocraft-<version>-linux-<arch>.tar.gz>
set -eu

TARBALL="${1:?usage: appimage.sh <photocraft-<version>-linux-<arch>.tar.gz>}"
ARCH="${ARCH:-$(uname -m)}"
REPO="${GITHUB_REPOSITORY:-storytold/photocraft}"
APP_ID=ai.storyteller.photocraft

VERSION="${PHOTOCRAFT_VERSION:-}"
if [ -z "$VERSION" ]; then
	VERSION="${TARBALL##*/}"
	VERSION="${VERSION#photocraft-}"
	VERSION="${VERSION%-linux-*.tar.gz}"
fi

# --strip-components=1 drops the tarball's photocraft-<version>-linux-<arch>/ top directory.
tar -xzf "$TARBALL" --strip-components=1 -C /

pacman -Syu --noconfirm \
	libxcursor \
	libxi \
	libxkbcommon \
	libxkbcommon-x11
get-debloated-pkgs --add-opengl --prefer-nano
# rfd falls back to zenity when it cannot reach the XDG desktop portal.
make-aur-package zenity-rs-bin

export ARCH
export VERSION
export OUTPATH="$PWD/dist/release"
export OUTNAME="photocraft-$VERSION-linux-$ARCH.AppImage"
export APPDIR="$PWD/AppDir"
export ADD_HOOKS="self-updater.hook"
export ICON="/usr/share/icons/hicolor/256x256/apps/$APP_ID.png"
export DESKTOP="/usr/share/applications/$APP_ID.desktop"
export DEPLOY_OPENGL=1
# Update information (#349), the same gh-releases-zsync string the other formats use.
export UPINFO="gh-releases-zsync|${REPO%%/*}|${REPO#*/}|latest|photocraft-*-linux-$ARCH.AppImage.zsync"

quick-sharun /usr/bin/photocraft /usr/bin/photocraft-cli /usr/bin/zenity
quick-sharun --make-appimage
quick-sharun --simple-test "$OUTPATH/$OUTNAME"

echo "wrote $OUTPATH/$OUTNAME"
