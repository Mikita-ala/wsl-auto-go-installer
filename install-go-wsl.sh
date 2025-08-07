#!/usr/bin/env bash
# install-go-wsl.sh
# Purpose  : Idempotent Go toolchain + code‑server setup for Ubuntu 22.04 WSL
# Usage    : bash install-go-wsl.sh [-v "1.23.3 1.24.5"] [--only]
# Default  : Installs the latest Go **only if not present**.
# Options  :
#   -v | --versions   space‑separated list of Go versions to ensure
#   --only            remove Go versions that are not in the list
#───────────────────────────────────────────────────────────────────────────────
set -euo pipefail

#─── 0. CLI parsing ───────────────────────────────────────────────────────────
GO_VERSIONS=()
ONLY=false
while [[ $# -gt 0 ]]; do
  case $1 in
    -v|--versions) shift; IFS=' ' read -r -a GO_VERSIONS <<< "${1:-}";;
    --only)        ONLY=true;;
    -h|--help)
      grep -E '^#( |$)' "$0" | sed -E 's/^# ?//'; exit 0;;
    *) echo "Unknown option: $1"; exit 1;;
  esac; shift || true
done

log(){ printf '\n\033[1;32m%s\033[0m\n' "$*"; }

#─── 1. OS check ──────────────────────────────────────────────────────────────
if ! lsb_release -dr | grep -q "Ubuntu 22.04"; then
  echo "❌ This script targets Ubuntu 22.04."; exit 1
fi

#─── 2. Base system packages ─────────────────────────────────────────────────
log "👉 Updating apt and installing base packages…"
BASE_PKGS=(
  build-essential git curl wget tar unzip ca-certificates
  software-properties-common linux-tools-common iproute2 net-tools htop
  docker.io
)
sudo apt update -qq
sudo apt install -y --no-install-recommends "${BASE_PKGS[@]}"

#─── 3. Enable systemd in WSL if missing ─────────────────────────────────────
enable_systemd_wsl(){
  [[ -f /etc/wsl.conf && $(grep -c "systemd=true" /etc/wsl.conf) -gt 0 ]] && return
  log "👉 Enabling systemd in WSL…"
  sudo tee /etc/wsl.conf >/dev/null <<'EOF'
[boot]
systemd=true
EOF
  log "🔄  Run 'wsl --shutdown' in Windows to apply systemd, then re‑launch WSL."
}
enable_systemd_wsl

#─── 4. Install / update asdf ────────────────────────────────────────────────
ASDF_DIR="$HOME/.asdf"
if [[ ! -d $ASDF_DIR ]]; then
  log "👉 Installing asdf…"
  git clone https://github.com/asdf-vm/asdf.git "$ASDF_DIR" --branch v0.13.1
fi
# shellcheck source=/dev/null
. "$ASDF_DIR/asdf.sh"
grep -q ".asdf.sh" ~/.bashrc || echo -e '\n. "$HOME/.asdf/asdf.sh"' >> ~/.bashrc

#─── 5. Go plugin ─────────────────────────────────────────────────────────────
if ! asdf plugin-list | grep -q '^go$'; then
  log "👉 Adding Go plugin…"
  asdf plugin-add go https://github.com/asdf-community/asdf-golang.git
fi
asdf plugin-update --all

#─── 6. Determine Go versions ────────────────────────────────────────────────
if [[ ${#GO_VERSIONS[@]} -eq 0 ]]; then
  GO_VERSIONS=( $(asdf list-all go | tail -1) )
fi
log "👉 Ensuring Go versions: ${GO_VERSIONS[*]}"
for V in "${GO_VERSIONS[@]}"; do
  asdf list go | grep -q "$V" || { log "⬇️  Installing Go $V"; asdf install go "$V"; }
done
asdf global go "${GO_VERSIONS[0]}"

#─── 7. Optionally purge other versions ──────────────────────────────────────
if $ONLY; then
  for V in $(asdf list go); do
    [[ " ${GO_VERSIONS[*]} " =~ " $V " ]] || { log "🗑  Removing Go $V"; asdf uninstall go "$V"; }
  done
fi

#─── 8. GOPATH / GOBIN export ────────────────────────────────────────────────
export_block='
### >>> Go defaults (install-go-wsl) >>>
export GOPATH="$HOME/go"
export GOBIN="$GOPATH/bin"
export PATH="$GOBIN:$PATH"
### <<< Go defaults <<<
'
grep -q "Go defaults (install-go-wsl)" ~/.profile || echo "$export_block" >> ~/.profile
grep -q "Go defaults (install-go-wsl)" ~/.bashrc  || echo "$export_block" >> ~/.bashrc
# shellcheck source=/dev/null
. ~/.profile

#─── 9. Install Go tools ─────────────────────────────────────────────────────
TOOLS=(
  "golang.org/x/tools/gopls@latest"
  "github.com/go-delve/delve/cmd/dlv@latest"
  "github.com/golangci/golangci-lint/cmd/golangci-lint@latest"
  "honnef.co/go/tools/cmd/staticcheck@latest"
  "github.com/golang/mock/mockgen@latest"
  "golang.org/x/tools/cmd/stringer@latest"
  "golang.org/x/vuln/cmd/govulncheck@latest"
)
log "👉 Installing Go tools…"
for TOOL in "${TOOLS[@]}"; do
  BIN=$(basename "${TOOL%@*}")
  command -v "$BIN" >/dev/null 2>&1 || go install "$TOOL"
done
asdf reshim go


#─── 11. Smoke tests ─────────────────────────────────────────────────────────
log "✅ SCRIPT FINISHED. Checks:"
go version
asdf list go
command -v gopls && gopls version || true