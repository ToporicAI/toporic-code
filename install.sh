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

case "${OS}-${ARCH}" in
  darwin-x86_64)  SLUG="macos-x64" ;;
  darwin-arm64)   SLUG="macos-arm64" ;;
  darwin-aarch64) SLUG="macos-arm64" ;;
  linux-x86_64)   SLUG="linux-x64" ;;
  linux-aarch64)  SLUG="linux-arm64" ;;
  *)
    echo "Unsupported platform: ${OS}-${ARCH}"
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
VERSION=$(curl -fsSL "$VERSION_JSON_URL" | sed -n 's/.*"version"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p')

if [ -z "$VERSION" ]; then
  echo "Failed to determine latest version."
  exit 1
fi

echo "Toporic ${VERSION} (${SLUG})"

# ── Download binary ───────────────────────────────────────────────────────────
RELEASE_URL="https://github.com/${REPO}/releases/download/v${VERSION}"
ARCHIVE="toporic-code-v${VERSION}-${SLUG}.tar.gz"
DOWNLOAD_URL="${RELEASE_URL}/${ARCHIVE}"

TMPDIR=$(mktemp -d)
trap 'rm -rf "$TMPDIR"' EXIT

echo "Downloading ${DOWNLOAD_URL} ..."
curl -fsSL "$DOWNLOAD_URL" -o "$TMPDIR/$ARCHIVE"

# ── Verify checksum ───────────────────────────────────────────────────────────
if [ -n "$SHA_CMD" ]; then
  SUMS_URL="${RELEASE_URL}/sha256sums.txt"
  SUMS_FILE="$TMPDIR/sha256sums.txt"

  if curl -fsSL "$SUMS_URL" -o "$SUMS_FILE" 2>/dev/null; then
    EXPECTED=$(awk -v f="$ARCHIVE" '$2 == f { print $1; exit }' "$SUMS_FILE")
    if [ -n "$EXPECTED" ]; then
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
