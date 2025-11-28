#!/bin/bash
# Mac Setup - Bootstrap Script
# Run with: curl -fsSL https://raw.githubusercontent.com/philippgerard/mac-setup/main/setup.sh | bash

set -e

echo ""
echo "========================================"
echo "  Mac Setup - Bootstrap Script"
echo "========================================"
echo ""

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

info() { echo -e "${GREEN}[INFO]${NC} $1"; }
warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
error() { echo -e "${RED}[ERROR]${NC} $1"; exit 1; }

# 1Password account for dotfiles
OP_ACCOUNT="my.1password.eu"

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

# 2. Homebrew
info "Checking Homebrew..."
if ! command -v brew &>/dev/null; then
    info "Installing Homebrew..."
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

    # Add Homebrew to PATH for this session
    eval "$(/opt/homebrew/bin/brew shellenv)"
else
    info "Homebrew already installed."
fi

# Ensure brew is in PATH
if [[ -f /opt/homebrew/bin/brew ]]; then
    eval "$(/opt/homebrew/bin/brew shellenv)"
fi

# 3. 1Password + CLI
info "Installing 1Password and CLI..."
brew install --cask 1password 1password-cli 2>/dev/null || true

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
read -p "Press Enter when 1Password is set up..."

# 4. Verify 1Password CLI
info "Verifying 1Password CLI connection..."
if ! op account list &>/dev/null; then
    error "1Password CLI not configured. Please set up 1Password first."
fi
info "1Password CLI connected successfully."

# 5. Get dotfiles repo from 1Password
info "Fetching configuration from 1Password..."
DOTFILES_REPO=$(op read "op://Dotfiles/Dotfiles Secrets/dotfiles-repo" --account "$OP_ACCOUNT" 2>/dev/null)
if [[ -z "$DOTFILES_REPO" ]]; then
    error "Could not read configuration from 1Password."
fi

# 6. Install chezmoi
info "Installing chezmoi..."
brew install chezmoi

# 7. Initialize and apply dotfiles
info "Initializing configuration..."
chezmoi init "$DOTFILES_REPO"

echo ""
info "Applying configuration (this may take a few minutes)..."
chezmoi apply

echo ""
echo "========================================"
echo "  Setup Complete!"
echo "========================================"
echo ""
info "Please restart your terminal."
