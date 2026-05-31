#!/usr/bin/env bash
set -euo pipefail

APP="toporic"
REPO="ToporicAI/toporic-code"
INSTALL_DIR="/usr/local/bin"

# ── Prerequisites ──────────────────────────────────────────────────────────────
if ! command -v curl &>/dev/null; then
  echo "Error: curl is required but not installed."
  echo "Install it first, then re-run this script."
  exit 1
fi

if ! command -v tar &>/dev/null; then
  echo "Error: tar is required but not installed."
  exit 1
fi

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

# ── Checksum tool detection ───────────────────────────────────────────────────
SHA_CMD=""
if command -v sha256sum &>/dev/null; then
  SHA_CMD="sha256sum"
elif command -v shasum &>/dev/null; then
  SHA_CMD="shasum -a 256"
fi

# ── Fetch latest version ──────────────────────────────────────────────────────
VERSION_JSON_URL="https://raw.githubusercontent.com/${REPO}/main/version.json"
VERSION=$(curl -fsSL "$VERSION_JSON_URL" | sed 's/.*"version":"\([^"]*\)".*/\1/')

if [ -z "$VERSION" ]; then
  echo "Failed to determine latest version."
  exit 1
fi

echo "Toporic ${VERSION} (${TARGET})"

# ── Download binary ───────────────────────────────────────────────────────────
RELEASE_URL="https://github.com/${REPO}/releases/download/v${VERSION}"
ARCHIVE="${APP}-v${VERSION}-${TARGET}.tar.gz"
DOWNLOAD_URL="${RELEASE_URL}/${ARCHIVE}"

TMPDIR=$(mktemp -d)
trap 'rm -rf "$TMPDIR"' EXIT

echo "Downloading ${DOWNLOAD_URL} ..."
curl -fsSL "$DOWNLOAD_URL" -o "$TMPDIR/$ARCHIVE"

# ── Verify checksum ───────────────────────────────────────────────────────────
if [ -n "$SHA_CMD" ]; then
  CHECK_URL="${DOWNLOAD_URL}.sha256"
  CHECK_FILE="$TMPDIR/${ARCHIVE}.sha256"

  if curl -fsSL "$CHECK_URL" -o "$CHECK_FILE" 2>/dev/null; then
    EXPECTED=$(cut -d' ' -f1 < "$CHECK_FILE")
    ACTUAL=$($SHA_CMD "$TMPDIR/$ARCHIVE" | cut -d' ' -f1)
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
tar -xzf "$TMPDIR/$ARCHIVE" -C "$TMPDIR"
BINARY="$TMPDIR/$APP"

if [ ! -x "$BINARY" ]; then
  echo "Binary not found after extraction."
  exit 1
fi

if [ ! -w "$INSTALL_DIR" ]; then
  echo "Installing to ${INSTALL_DIR} (requires sudo)..."
  sudo cp "$BINARY" "${INSTALL_DIR}/${APP}"
else
  cp "$BINARY" "${INSTALL_DIR}/${APP}"
fi

echo ""
echo "Installed ${APP} ${VERSION} to ${INSTALL_DIR}/${APP}"
echo "Run '${APP} --help' to get started."
