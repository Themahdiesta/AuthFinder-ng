#!/usr/bin/env bash
# authfinder-ng — One-liner installer
# Usage: bash install.sh

set -e

GREEN=$'\033[1;32m'; CYAN=$'\033[1;36m'; RED=$'\033[1;31m'; NC=$'\033[0m'
ok()   { echo -e "${GREEN}[+]${NC} $*"; }
info() { echo -e "${CYAN}[*]${NC} $*"; }
fail() { echo -e "${RED}[-]${NC} $*"; }

echo -e "${CYAN}"
cat << 'BANNER'
  ╔══════════════════════════════════════════════╗
  ║   authfinder-ng v4.0 — Installer            ║
  ╚══════════════════════════════════════════════╝
BANNER
echo -e "${NC}"

INSTALL_DIR="/usr/local/bin"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Install main script
info "Installing authfinder-ng to ${INSTALL_DIR}..."
sudo cp "${SCRIPT_DIR}/authfinder-ng" "${INSTALL_DIR}/authfinder-ng"
sudo chmod +x "${INSTALL_DIR}/authfinder-ng"
ok "Installed: ${INSTALL_DIR}/authfinder-ng"

# Verify
if command -v authfinder-ng &>/dev/null; then
    ok "authfinder-ng is in PATH"
else
    fail "Not in PATH — add ${INSTALL_DIR} to your \$PATH"
fi

echo ""
info "Installing dependencies..."
authfinder-ng --install-tools

echo ""
ok "Done! Try: authfinder-ng --check-tools"
