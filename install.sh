#!/usr/bin/env sh
# Toporic installer — Unix (macOS & Linux)
# Usage:
#   curl -fsSL https://raw.githubusercontent.com/ToporicAI/toporic-code/main/install.sh | sh
#   or with a specific version:
#   curl -fsSL https://raw.githubusercontent.com/ToporicAI/toporic-code/main/install.sh | sh -s -- --version 1.2.3

set -eu

REPO="ToporicAI/toporic-code"
BINARY="toporic"
INSTALL_DIR="${TOPORIC_INSTALL_DIR:-}"

# ── Helpers ──────────────────────────────────────────────────────────────────

say()  { printf "  \033[1;32m>\033[0m %s\n" "$*"; }
warn() { printf "  \033[1;33m!\033[0m %s\n" "$*"; }
err()  { printf "  \033[1;31mx\033[0m %s\n" "$*" >&2; exit 1; }

need() {
    command -v "$1" >/dev/null 2>&1 || err "Required command not found: $1"
}

# ── Argument parsing ──────────────────────────────────────────────────────────

VERSION=""
while [ $# -gt 0 ]; do
    case "$1" in
        --version|-v) VERSION="$2"; shift 2 ;;
        --install-dir) INSTALL_DIR="$2"; shift 2 ;;
        --help|-h)
            echo "Usage: install.sh [--version X.Y.Z] [--install-dir /path]"
            exit 0
            ;;
        *) err "Unknown argument: $1" ;;
    esac
done

# ── Detect OS and architecture ────────────────────────────────────────────────

OS="$(uname -s)"
ARCH="$(uname -m)"

case "$OS" in
    Darwin)
        case "$ARCH" in
            x86_64)           TARGET="x86_64-apple-darwin" ;;
            arm64|aarch64)    TARGET="aarch64-apple-darwin" ;;
            *)                err "Unsupported macOS architecture: $ARCH" ;;
        esac
        ARCHIVE_EXT="tar.gz"
        DEFAULT_DIR="/usr/local/bin"
        ;;
    Linux)
        case "$ARCH" in
            x86_64)           TARGET="x86_64-unknown-linux-gnu" ;;
            aarch64|arm64)    TARGET="aarch64-unknown-linux-gnu" ;;
            *)                err "Unsupported Linux architecture: $ARCH" ;;
        esac
        ARCHIVE_EXT="tar.gz"
        DEFAULT_DIR="${HOME}/.local/bin"
        ;;
    *)
        err "Unsupported OS: $OS. Use install.ps1 on Windows."
        ;;
esac

# ── Resolve install directory ─────────────────────────────────────────────────

if [ -z "$INSTALL_DIR" ]; then
    # Prefer /usr/local/bin if writable, else fall back to ~/.local/bin
    if [ -w "/usr/local/bin" ]; then
        INSTALL_DIR="/usr/local/bin"
    else
        INSTALL_DIR="$DEFAULT_DIR"
    fi
fi

mkdir -p "$INSTALL_DIR"

# ── Resolve version ───────────────────────────────────────────────────────────

need curl

if [ -z "$VERSION" ]; then
    say "Fetching latest release version..."
    VERSION="$(curl -fsSL "https://api.github.com/repos/${REPO}/releases/latest" \
        | grep '"tag_name"' | sed 's/.*"tag_name": *"v\([^"]*\)".*/\1/')"
    [ -n "$VERSION" ] || err "Could not determine latest version. Use --version to specify one."
fi

TAG="v${VERSION}"
say "Installing ${BINARY} ${TAG} for ${TARGET}..."

# ── Download and verify ───────────────────────────────────────────────────────

ARCHIVE="${BINARY}-${TAG}-${TARGET}.${ARCHIVE_EXT}"
BASE_URL="https://github.com/${REPO}/releases/download/${TAG}"

TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

say "Downloading ${ARCHIVE}..."
curl -fsSL --progress-bar "${BASE_URL}/${ARCHIVE}" -o "${TMP}/${ARCHIVE}"
curl -fsSL "${BASE_URL}/sha256sums.txt" -o "${TMP}/sha256sums.txt"

say "Verifying checksum..."
cd "$TMP"
if command -v sha256sum >/dev/null 2>&1; then
    grep "$ARCHIVE" sha256sums.txt | sha256sum -c - || err "Checksum verification failed!"
elif command -v shasum >/dev/null 2>&1; then
    grep "$ARCHIVE" sha256sums.txt | shasum -a 256 -c - || err "Checksum verification failed!"
else
    warn "No sha256 tool found — skipping checksum verification."
fi
cd - >/dev/null

# ── Extract and install ───────────────────────────────────────────────────────

say "Extracting..."
tar -xzf "${TMP}/${ARCHIVE}" -C "${TMP}"

DEST="${INSTALL_DIR}/${BINARY}"
if [ -f "$DEST" ] && [ ! -w "$DEST" ]; then
    err "Cannot write to ${DEST}. Try: sudo sh install.sh --install-dir /usr/local/bin"
fi

mv "${TMP}/${BINARY}" "$DEST"
chmod +x "$DEST"

# ── PATH check ────────────────────────────────────────────────────────────────

say "Installed to ${DEST}"

if ! echo "$PATH" | grep -q "$INSTALL_DIR"; then
    warn "${INSTALL_DIR} is not in your PATH."
    warn "Add this to your shell profile (e.g. ~/.bashrc, ~/.zshrc):"
    warn "  export PATH=\"${INSTALL_DIR}:\$PATH\""
fi

# ── Done ─────────────────────────────────────────────────────────────────────

say "Done! Run: ${BINARY} --version"
