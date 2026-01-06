#!/bin/bash
# Mac Setup - Bootstrap Script
# Run with: curl -fsSL https://raw.githubusercontent.com/philippgerard/mac-setup/main/setup.sh | bash

set -e

echo ""
echo "========================================"
echo "  Mac Setup - Nix Bootstrap"
echo "========================================"
echo ""

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

info() { echo -e "${GREEN}[INFO]${NC} $1"; }
warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
error() { echo -e "${RED}[ERROR]${NC} $1"; exit 1; }

# Configuration
REPO_URL="https://github.com/philippgerard/mac-setup.git"
CONFIG_DIR="$HOME/.config/mac-setup"

# 1. Xcode Command Line Tools
info "Checking Xcode Command Line Tools..."
if ! xcode-select -p &>/dev/null; then
    info "Installing Xcode Command Line Tools..."
    xcode-select --install
    echo ""
    warn "Please complete the Xcode tools installation popup."
    read -p "Press Enter when Xcode tools are installed..."
else
    info "Xcode Command Line Tools already installed."
fi

# 2. Homebrew (installed directly from Homebrew, not via third-party Nix flake)
info "Checking Homebrew..."
if ! command -v brew &>/dev/null; then
    info "Installing Homebrew..."
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
fi

# Ensure brew is in PATH (Apple Silicon)
if [[ -f /opt/homebrew/bin/brew ]]; then
    eval "$(/opt/homebrew/bin/brew shellenv)"
fi
# Intel Mac
if [[ -f /usr/local/bin/brew ]]; then
    eval "$(/usr/local/bin/brew shellenv)"
fi

if command -v brew &>/dev/null; then
    info "Homebrew installed: $(brew --version | head -1)"
else
    error "Homebrew installation failed."
fi

# 3. Install Determinate Nix
info "Checking Nix installation..."
if ! command -v nix &>/dev/null; then
    info "Installing Determinate Nix..."
    curl -fsSL https://install.determinate.systems/nix | sh -s -- install --determinate

    # Source nix
    if [[ -f /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh ]]; then
        . /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh
    fi
else
    info "Nix already installed."
fi

# Ensure nix is in PATH
if ! command -v nix &>/dev/null; then
    error "Nix not found in PATH. Please restart your terminal and run this script again."
fi

# 4. Clone or update the configuration repository
info "Setting up configuration repository..."
if [[ -d "$CONFIG_DIR" ]]; then
    info "Configuration directory exists, pulling latest..."
    git -C "$CONFIG_DIR" pull
else
    info "Cloning configuration repository..."
    git clone "$REPO_URL" "$CONFIG_DIR"
fi

# 5. Build hostname from device type and purpose
USERNAME="philippgerard"

echo ""
echo "========================================"
echo "  Device Configuration"
echo "========================================"
echo ""

# Select device type
echo "What type of device is this?"
echo ""
echo -e "  ${BLUE}1)${NC} desktop"
echo -e "  ${BLUE}2)${NC} laptop"
echo ""

while true; do
    read -p "Enter your choice (1-2): " type_choice
    case $type_choice in
        1) DEVICE_TYPE="desktop"; break ;;
        2) DEVICE_TYPE="laptop"; break ;;
        *) warn "Invalid choice. Please enter 1 or 2." ;;
    esac
done

echo ""

# Select purpose
echo "What is this device used for?"
echo ""
echo -e "  ${BLUE}1)${NC} personal"
echo -e "  ${BLUE}2)${NC} work"
echo ""

while true; do
    read -p "Enter your choice (1-2): " purpose_choice
    case $purpose_choice in
        1) PURPOSE="personal"; break ;;
        2) PURPOSE="work"; break ;;
        *) warn "Invalid choice. Please enter 1 or 2." ;;
    esac
done

# Build hostname
HOSTNAME="${USERNAME}-${DEVICE_TYPE}-${PURPOSE}"

echo ""
info "Hostname will be: $HOSTNAME"

# 6. Set macOS hostname
CURRENT_HOSTNAME=$(hostname -s)
if [[ "$CURRENT_HOSTNAME" != "$HOSTNAME" ]]; then
    echo ""
    info "Setting hostname to '$HOSTNAME'..."
    sudo scutil --set ComputerName "$HOSTNAME"
    sudo scutil --set HostName "$HOSTNAME"
    sudo scutil --set LocalHostName "$HOSTNAME"
    sudo dscacheutil -flushcache
    info "Hostname updated successfully."
else
    info "Hostname already set to '$HOSTNAME'."
fi

# 7. Initial nix-darwin build
info "Building nix-darwin configuration..."
cd "$CONFIG_DIR"

# First-time nix-darwin installation
if ! command -v darwin-rebuild &>/dev/null; then
    info "Installing nix-darwin for the first time..."
    nix run nix-darwin -- switch --flake ".#$HOSTNAME"
else
    info "Running darwin-rebuild..."
    darwin-rebuild switch --flake ".#$HOSTNAME"
fi

# 8. 1Password setup reminder
echo ""
echo "========================================"
echo "  MANUAL STEP REQUIRED"
echo "========================================"
echo ""
echo "1. Open 1Password and sign in to your account"
echo "2. Go to Settings > Developer"
echo "3. Enable 'Integrate with 1Password CLI'"
echo "4. Enable 'Use the SSH agent'"
echo ""

# 9. Success
echo ""
echo "========================================"
echo "  Setup Complete!"
echo "========================================"
echo ""
info "Device: $HOSTNAME"
info "Configuration: $CONFIG_DIR"
echo ""
echo "Useful commands:"
echo "  darwin-rebuild switch --flake ~/.config/mac-setup#$HOSTNAME  # Rebuild"
echo "  nix flake update ~/.config/mac-setup                         # Update flake"
echo ""
info "Please restart your terminal to apply all changes."
