#!/usr/bin/env bash
set -euo pipefail

APP="toporic"
REPO="ToporicAI/toporic-code"
INSTALL_DIR="/usr/local/bin"

# ── Platform detection ────────────────────────────────────────────────────────
ARCH=$(uname -m)
OS=$(uname -s | tr '[:upper:]' '[:lower:]')

case "$OS" in
  linux)  TARGET_SUFFIX="unknown-linux-gnu" ;;
  darwin) TARGET_SUFFIX="apple-darwin"       ;;
  *)
    echo "Unsupported OS: $OS"
    exit 1
    ;;
esac

case "$ARCH" in
  x86_64)  TARGET="${ARCH}-${TARGET_SUFFIX}"   ;;
  aarch64) TARGET="aarch64-${TARGET_SUFFIX}"    ;;
  arm64)   TARGET="aarch64-${TARGET_SUFFIX}"    ;;
  *)
    echo "Unsupported architecture: $ARCH"
    exit 1
    ;;
esac

# ── Fetch latest version ─────────────────────────────────────────────────────
VERSION_JSON_URL="https://toporic.com/code/tui/version.json"
VERSION=$(curl -fsSL "$VERSION_JSON_URL" | sed -n 's/.*"version": "\([^"]*\)".*/\1/p')

if [ -z "$VERSION" ]; then
  echo "Failed to determine latest version"
  exit 1
fi

echo "Toporic ${VERSION} (${TARGET})"

# ── Download binary ───────────────────────────────────────────────────────────
RELEASE_URL="https://github.com/${REPO}/releases/download/v${VERSION}"
ARCHIVE="toporic-code-v${VERSION}-${TARGET}.tar.gz"
DOWNLOAD_URL="${RELEASE_URL}/${ARCHIVE}"

TMPDIR=$(mktemp -d)
trap 'rm -rf "$TMPDIR"' EXIT

echo "Downloading ${DOWNLOAD_URL} ..."
curl -fL --http1.1 --progress-bar "$DOWNLOAD_URL" -o "$TMPDIR/$ARCHIVE"

# ── Verify checksum ───────────────────────────────────────────────────────────
CHECK_URL="${RELEASE_URL}/sha256sums.txt"
CHECK_FILE="$TMPDIR/sha256sums.txt"

echo "Verifying checksum ..."
if curl -fsSL --http1.1 "$CHECK_URL" -o "$CHECK_FILE" 2>/dev/null; then
  EXPECTED=$(grep "$ARCHIVE" "$CHECK_FILE" | cut -d' ' -f1)
  if [ -n "$EXPECTED" ]; then
    ACTUAL=$(sha256sum "$TMPDIR/$ARCHIVE" | cut -d' ' -f1)
    if [ "$EXPECTED" != "$ACTUAL" ]; then
      echo "Checksum mismatch!"
      echo "  Expected: ${EXPECTED}"
      echo "  Actual:   ${ACTUAL}"
      exit 1
    fi
    echo "Checksum verified."
  fi
fi

# ── Extract and install ───────────────────────────────────────────────────────
echo "Extracting ..."
tar -xzf "$TMPDIR/$ARCHIVE" -C "$TMPDIR"
BINARY="$TMPDIR/$APP"

if [ ! -x "$BINARY" ]; then
  echo "Binary not found after extraction"
  exit 1
fi

echo "Installing to ${INSTALL_DIR} ..."
if [ ! -w "$INSTALL_DIR" ]; then
  echo "(requires sudo)"
  sudo cp "$BINARY" "${INSTALL_DIR}/${APP}"
else
  cp "$BINARY" "${INSTALL_DIR}/${APP}"
fi

if [ "$OS" = "darwin" ]; then
  xattr -d com.apple.quarantine "${INSTALL_DIR}/${APP}" 2>/dev/null || true
fi

echo "Installed ${APP} ${VERSION} to ${INSTALL_DIR}/${APP}"
echo "Ready. Run 'toporic' in your working directory to start, or 'toporic --help' for all options."
