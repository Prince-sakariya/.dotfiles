#!/usr/bin/env bash
echo "Setting up development environment..."

set -euo pipefail

if ! cat /etc/os-release | grep "^ID=ubuntu"; then
    echo "This script only supports Ubuntu." >&2
    exit 1
fi

# ----------------------------------------------------------------------------
# Configuration
# ----------------------------------------------------------------------------

DOTFILES_REPO="https://github.com/Prince-sakariya/.dotfiles.git"
DOTFILES_REPO_BRANCH="feature/ubuntu"
DOTFILES="${HOME}/.dotfiles"

NVIM_VERSION="0.12.5"

NVIM_CONFIG_REPO="https://github.com/Prince-sakariya/nvim-configs.git"
NVIM_REPO_BRANCH="linux"
NVIM_INSTALL_DIR="/opt/nvim"
NVIM_CONFIG_DIR="${HOME}/.config/nvim"

# ----------------------------------------------------------------------------
# Exports
# ----------------------------------------------------------------------------
export PATH="$HOME/.cargo/bin:$PATH"
export PATH="$HOME/.yarn/bin:$HOME/.config/yarn/global/node_modules/.bin:$PATH"


# ----------------------------------------------------------------------------
# Helpers
# ----------------------------------------------------------------------------

info() {
    printf '\n==> %s\n' "$1"
}

tmp_dir="$(mktemp -d)"
trap 'rm -rf "$tmp_dir"' EXIT

# OH MY ZSH

if [[ -d "$HOME/.oh-my-zsh" ]]; then
    info "Oh My Zsh already installed"
else
    info "Installing Oh My Zsh"
    printf 'n\n' | sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
fi

# ----------------------------------------------------------------------------
# System packages
# ----------------------------------------------------------------------------

info "Installing dependencies"

sudo apt-get update
sudo apt-get install -y \
    zsh \
    git \
    stow \
    curl \
    wget \
    unzip \
    build-essential \
    ripgrep \
    fd-find \
    xclip \
    lua5.1 \
    liblua5.1-dev\
    tmux\
    python3 \
    python3-pip \
    python3-venv \
    clang-format

# ----------------------------------------------------------------------------
# Install Neovim
# ----------------------------------------------------------------------------
if command -v nvim > /dev/null 2>&1; then
    info "Neovim already installed: $(nvim --version | head -n1)"
else
    info "Installing Neovim ${NVIM_VERSION}"

    mdir -p "$tmp_dir/nvim"
    cd "$tmp_dir/nvim"

    curl -LO "https://github.com/neovim/neovim/releases/download/v${NVIM_VERSION}/nvim-linux-x86_64.tar.gz"

    sudo mkdir -p "${NVIM_INSTALL_DIR}"
    sudo tar -xzf "nvim-linux-x86_64.tar.gz" \
        -C "${NVIM_INSTALL_DIR}" \
        --strip-components=1

    sudo ln -sf "${NVIM_INSTALL_DIR}/bin/nvim" /usr/local/bin/nvim
fi

# ----------------------------------------------------------------------------
# Neovim config
# ----------------------------------------------------------------------------

info "Installing Neovim configuration"

if [ -d "${NVIM_CONFIG_DIR}" ]; then
    info "Neovim config already exists: ${NVIM_CONFIG_DIR}"
else
    mkdir -p "$(dirname "${NVIM_CONFIG_DIR}")"

    git clone --branch "${NVIM_REPO_BRANCH}" "${NVIM_CONFIG_REPO}" "${NVIM_CONFIG_DIR}"
fi

# ----------------------------------------------------------------------------
# .dotfiles
# ----------------------------------------------------------------------------

info "Installing .dotfiles"

if [ -d "${DOTFILES}" ]; then
    info ".dotfiles already exist"
else
    mkdir -p "$(dirname "${DOTFILES}")"

    git clone --branch "${DOTFILES_REPO_BRANCH}" "${DOTFILES_REPO}" "${DOTFILES}"
fi

echo "Executing .dotfiles/ubuntu"
bash ${DOTFILES}/ubuntu

# ----------------------------------------------------------------------------
#                       INSTALL EXTRAS
#
#
# ----------------------------------------------------------------------------
# Install Rust / Cargo
# ----------------------------------------------------------------------------

if command -v cargo > /dev/null 2>&1; then
    info "Rust already installed: $(cargo --version)"
else
    info "Installing Rust"

    curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
fi

# ----------------------------------------------------------------------------
# Install Tree-sitter CLI
# ----------------------------------------------------------------------------
if command -v tree-sitter > /dev/null 2>&1; then
    info "Tree-sitter already installed: $(tree-sitter --version)"
else
    info "Installing Tree-sitter CLI"
    cargo install --locked tree-sitter-cli
fi

# ----------------------------------------------------------------------------
# Install Node, yarn, etc.
# ----------------------------------------------------------------------------

if ! command -v nvm > /dev/null 2>&1; then
    info "Installing nvm"

    curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.3/install.sh | bash

    set +u
    export NVM_DIR="$HOME/.nvm"
    [ -s "$NVM_DIR/nvm.sh" ] && . "$NVM_DIR/nvm.sh"
    set -u
else
    set +u
    export NVM_DIR="$HOME/.nvm"
    [ -s "$NVM_DIR/nvm.sh" ] && . "$NVM_DIR/nvm.sh"
    set -u
fi

if command -v node > /dev/null 2>&1; then
    info "Node already installed: $(node --version)"
else
    info "Installing Node.js"
    nvm install --lts
    nvm use --lts
fi

if command -v yarn > /dev/null 2>&1; then
    info "Yarn already installed: $(yarn --version)"
else
    info "Installing Yarn"

    curl -o- -L https://yarnpkg.com/install.sh | bash
fi
yarn global add neovim

# ----------------------------------------------------------------------------
# Install Lua / LuaRocks
# ----------------------------------------------------------------------------

info "Installing Lua / LuaRocks"

if command -v luarocks > /dev/null 2>&1; then
    info "LuaRocks already installed: $(luarocks --version | head -n1)"
else
    info "Installing LuaRocks"

    mkdir -p "$tmp_dir/luarocks"
    cd "$tmp_dir/luarocks"

    wget https://luarocks.org/releases/luarocks-3.13.0.tar.gz
    tar zxpf luarocks-3.13.0.tar.gz
    cd luarocks-3.13.0

    ./configure
    make
    sudo make install
fi

# ----------------------------------------------------------------------------
# Formatters & Linters
# ----------------------------------------------------------------------------

if ! command -v prettier > /dev/null 2>&1; then
    yarn global add prettier
fi

if ! command -v ruff > /dev/null 2>&1; then
    curl -LsSf https://astral.sh/ruff/install.sh | sh
fi

if ! command -v stylua > /dev/null 2>&1; then
    cargo install stylua
fi


# ----------------------------------------------------------------------------
# Done
# ----------------------------------------------------------------------------

info "Setup complete"
info "Run 'exec bash' (or 'exec zsh' if you use zsh) to reload your shell."

nvim --version | head -n1
