#!/bin/bash

# =============================================================================
# Starship Setup Script - Clean & Minimal
# Supports: Linux (Ubuntu/Debian/Arch/Fedora), macOS
# Includes: Starship, Alacritty (macOS only), eza, zoxide, tmux
# =============================================================================

set -e

# Starship config from gist (raw URL)
STARSHIP_GIST_URL="https://gist.githubusercontent.com/Ba-koD/9c7888b1cc74e31b671f5bc2c26bca8e/raw/starship.toml"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

print_info() { echo -e "${BLUE}[INFO]${NC} $1"; }
print_success() { echo -e "${GREEN}[SUCCESS]${NC} $1"; }
print_warning() { echo -e "${YELLOW}[WARNING]${NC} $1"; }
print_error() { echo -e "${RED}[ERROR]${NC} $1"; }

# Detect OS
detect_os() {
    if [[ "$OSTYPE" == "darwin"* ]]; then
        echo "macos"
    elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
        echo "linux"
    else
        echo "unknown"
    fi
}

is_apple_silicon() {
    [[ "$OSTYPE" == "darwin"* ]] && [[ "$(uname -m)" == "arm64" ]]
}

detect_linux_distro() {
    if [ -f /etc/os-release ]; then
        . /etc/os-release
        echo "$ID"
    else
        echo "unknown"
    fi
}

OS=$(detect_os)
[[ "$OS" == "linux" ]] && DISTRO=$(detect_linux_distro)

echo ""
echo "=============================================="
echo "  Starship Setup Script"
echo "=============================================="
echo ""
print_info "Detected OS: $OS"
[[ "$OS" == "linux" ]] && print_info "Detected distro: $DISTRO"
echo ""

read -p "Proceed with installation? [Y/n] " -n 1 -r
echo ""
[[ ! $REPLY =~ ^[Yy]$ ]] && [[ ! -z $REPLY ]] && exit 0

# ============================================
# STEP 1: Package manager setup
# ============================================
echo ""
echo "[1/12] Setting up package manager..."
if [[ "$OS" == "macos" ]]; then
    if ! command -v brew &> /dev/null; then
        /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
        if is_apple_silicon; then
            echo 'eval "$(/opt/homebrew/bin/brew shellenv)"' >> ~/.zprofile
            eval "$(/opt/homebrew/bin/brew shellenv)"
        fi
    fi
elif [[ "$OS" == "linux" ]]; then
    case "$DISTRO" in
        ubuntu|debian|pop|linuxmint) sudo apt update ;;
        arch|manjaro|endeavouros) sudo pacman -Sy ;;
        fedora) sudo dnf check-update || true ;;
    esac
fi

# ============================================
# STEP 2: Install FiraCode Nerd Font
# ============================================
echo ""
echo "[2/12] Installing FiraCode Nerd Font..."
if [[ "$OS" == "macos" ]]; then
    if ! brew list font-fira-code-nerd-font &> /dev/null 2>&1; then
        brew tap homebrew/cask-fonts 2>/dev/null || true
        brew install --cask font-fira-code-nerd-font
    else
        echo "Already installed, skipping..."
    fi
elif [[ "$OS" == "linux" ]]; then
    if ! fc-list | grep -qi "FiraCode.*Nerd" 2>/dev/null; then
        mkdir -p "$HOME/.local/share/fonts"
        temp_dir=$(mktemp -d)
        curl -fLo "$temp_dir/FiraCode.zip" \
            "https://github.com/ryanoasis/nerd-fonts/releases/latest/download/FiraCode.zip"
        unzip -q "$temp_dir/FiraCode.zip" -d "$HOME/.local/share/fonts/FiraCodeNerdFont"
        fc-cache -f -v > /dev/null 2>&1
        rm -rf "$temp_dir"
    else
        echo "Already installed, skipping..."
    fi
fi

# ============================================
# STEP 3: Install Alacritty (macOS only)
# ============================================
echo ""
echo "[3/12] Installing Alacritty..."
if [[ "$OS" == "macos" ]]; then
    if ! brew list --cask alacritty &> /dev/null 2>&1; then
        brew install --cask alacritty
    else
        echo "Already installed, skipping..."
    fi
else
    echo "Skipping (macOS only)..."
fi

# ============================================
# STEP 4: Configure Alacritty (macOS only)
# ============================================
echo ""
echo "[4/12] Configuring Alacritty..."
if [[ "$OS" == "macos" ]]; then
    ALACRITTY_DIR="$HOME/.config/alacritty"
    mkdir -p "$ALACRITTY_DIR/themes/themes"
    
    [ ! -d "$ALACRITTY_DIR/themes/.git" ] && \
        git clone https://github.com/alacritty/alacritty-theme "$ALACRITTY_DIR/themes"
    
    [ ! -f "$ALACRITTY_DIR/themes/themes/coolnight.toml" ] && \
        curl -fsSL https://raw.githubusercontent.com/josean-dev/dev-environment-files/main/.config/alacritty/themes/themes/coolnight.toml \
        -o "$ALACRITTY_DIR/themes/themes/coolnight.toml"
    
    if [ ! -f "$ALACRITTY_DIR/alacritty.toml" ]; then
        cat > "$ALACRITTY_DIR/alacritty.toml" << 'EOF'
import = ["~/.config/alacritty/themes/themes/coolnight.toml"]

[env]
TERM = "xterm-256color"

[window]
padding = { x = 10, y = 10 }
decorations = "Buttonless"
opacity = 0.7
blur = true
option_as_alt = "Both"

[font]
normal = { family = "FiraCode Nerd Font", style = "Regular" }
size = 18
EOF
    fi
else
    echo "Skipping (macOS only)..."
fi

# ============================================
# STEP 5: Install Starship
# ============================================
echo ""
echo "[5/12] Installing Starship..."
if ! command -v starship &> /dev/null; then
    if [[ "$OS" == "macos" ]]; then
        brew install starship
    elif [[ "$OS" == "linux" ]]; then
        case "$DISTRO" in
            arch|manjaro|endeavouros) sudo pacman -S --noconfirm starship ;;
            fedora) sudo dnf install -y starship ;;
            *) curl -sS https://starship.rs/install.sh | sh -s -- -y ;;
        esac
    fi
else
    echo "Already installed, skipping..."
fi

# Configure Starship
echo "Configuring Starship..."
mkdir -p "$HOME/.config"
if [ ! -f "$HOME/.config/starship.toml" ]; then
    # Download starship config from gist
    if [[ "$STARSHIP_GIST_URL" != "YOUR_GIST_RAW_URL_HERE" ]] && curl -fsSL "$STARSHIP_GIST_URL" -o "$HOME/.config/starship.toml" 2>/dev/null; then
        print_success "Starship config downloaded from gist"
    else
        print_warning "Gist URL not set or download failed, using default preset"
        starship preset bracketed-segments -o "$HOME/.config/starship.toml"
    fi
fi
# ============================================
# STEP 6: Install eza
# ============================================
echo ""
echo "[6/12] Installing eza..."
if ! command -v eza &> /dev/null; then
    if [[ "$OS" == "macos" ]]; then
        brew install eza
    elif [[ "$OS" == "linux" ]]; then
        case "$DISTRO" in
            arch|manjaro|endeavouros) sudo pacman -S --noconfirm eza ;;
            fedora) sudo dnf install -y eza ;;
            *)
                EZA_VERSION=$(curl -s "https://api.github.com/repos/eza-community/eza/releases/latest" | grep -Po '"tag_name": "v\K[^"]*')
                curl -Lo /tmp/eza.tar.gz "https://github.com/eza-community/eza/releases/download/v${EZA_VERSION}/eza_x86_64-unknown-linux-gnu.tar.gz"
                sudo tar xzf /tmp/eza.tar.gz -C /usr/local/bin
                rm /tmp/eza.tar.gz
                ;;
        esac
    fi
else
    echo "Already installed, skipping..."
fi

# ============================================
# STEP 7: Install zoxide
# ============================================
echo ""
echo "[7/12] Installing zoxide..."
if ! command -v zoxide &> /dev/null; then
    if [[ "$OS" == "macos" ]]; then
        brew install zoxide
    elif [[ "$OS" == "linux" ]]; then
        case "$DISTRO" in
            arch|manjaro|endeavouros) sudo pacman -S --noconfirm zoxide ;;
            fedora) sudo dnf install -y zoxide ;;
            *) curl -sS https://raw.githubusercontent.com/ajeetdsouza/zoxide/main/install.sh | bash ;;
        esac
    fi
else
    echo "Already installed, skipping..."
fi

# ============================================
# STEP 8: Install atuin (better history)
# ============================================
echo ""
echo "[8/12] Installing atuin..."

# Add atuin bin path for current session (installer installs to ~/.atuin/bin)
export PATH="$HOME/.atuin/bin:$PATH"

if ! command -v atuin &> /dev/null; then
    if [[ "$OS" == "macos" ]]; then
        brew install atuin
    elif [[ "$OS" == "linux" ]]; then
        case "$DISTRO" in
            arch|manjaro|endeavouros) sudo pacman -S --noconfirm atuin ;;
            *)
                # Download installer script directly from GitHub releases
                curl --proto '=https' --tlsv1.2 -LsSf \
                    https://github.com/atuinsh/atuin/releases/latest/download/atuin-installer.sh | sh
                # Refresh PATH after installation
                export PATH="$HOME/.atuin/bin:$PATH"
                ;;
        esac
    fi
else
    echo "Already installed, skipping..."
fi

# ============================================
# STEP 9: Install tmux
# ============================================
echo ""
echo "[9/12] Installing tmux..."
if ! command -v tmux &> /dev/null; then
    if [[ "$OS" == "macos" ]]; then
        brew install tmux
    elif [[ "$OS" == "linux" ]]; then
        case "$DISTRO" in
            ubuntu|debian|pop|linuxmint) sudo apt install -y tmux ;;
            arch|manjaro|endeavouros) sudo pacman -S --noconfirm tmux ;;
            fedora) sudo dnf install -y tmux ;;
        esac
    fi
else
    echo "Already installed, skipping..."
fi

[[ "$OS" == "macos" ]] && ! brew list bash &> /dev/null 2>&1 && brew install bash

if [ ! -f "$HOME/.tmux.conf" ]; then
    curl -fsSL https://raw.githubusercontent.com/josean-dev/dev-environment-files/main/.tmux.conf -o ~/.tmux.conf
fi

if [ ! -d "$HOME/.tmux/plugins/tpm" ]; then
    git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm
fi

# ============================================
# STEP 10: Install zsh plugins (zsh only)
# ============================================
echo ""
echo "[10/12] Installing zsh plugins (syntax-highlighting, autosuggestions)..."

CURRENT_SHELL=$(basename "$SHELL")

if [[ "$CURRENT_SHELL" == "zsh" ]]; then
    ZSH_PLUGIN_DIR="$HOME/.zsh"
    mkdir -p "$ZSH_PLUGIN_DIR"
    
    # Install zsh-syntax-highlighting
    if [ ! -d "$ZSH_PLUGIN_DIR/zsh-syntax-highlighting" ]; then
        git clone https://github.com/zsh-users/zsh-syntax-highlighting.git "$ZSH_PLUGIN_DIR/zsh-syntax-highlighting"
        print_success "zsh-syntax-highlighting installed"
    else
        echo "zsh-syntax-highlighting already installed, skipping..."
    fi
    
    # Install zsh-autosuggestions
    if [ ! -d "$ZSH_PLUGIN_DIR/zsh-autosuggestions" ]; then
        git clone https://github.com/zsh-users/zsh-autosuggestions.git "$ZSH_PLUGIN_DIR/zsh-autosuggestions"
        print_success "zsh-autosuggestions installed"
    else
        echo "zsh-autosuggestions already installed, skipping..."
    fi
else
    echo "Skipping (zsh only)..."
fi

# ============================================
# STEP 11: Configure shell
# ============================================
echo ""
echo "[11/12] Configuring shell..."

configure_shell() {
    local rc_file=$1
    local init_cmd=$2
    
    # Ask user if they want to reset the rc file
    if [ -f "$rc_file" ]; then
        echo ""
        read -p "$(echo -e "${YELLOW}[QUESTION]${NC} $rc_file already exists. Reset it? [y/N] ")" -n 1 -r
        echo ""
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            cp "$rc_file" "$rc_file.backup.$(date +%Y%m%d_%H%M%S)"
            print_info "Backup created: $rc_file.backup.$(date +%Y%m%d_%H%M%S)"
            rm "$rc_file"
            print_info "Resetting $rc_file..."
        else
            # Check if already configured
            if grep -q "starship init" "$rc_file" 2>/dev/null; then
                echo "Already configured, skipping..."
                return
            fi
            # Backup before appending
            cp "$rc_file" "$rc_file.backup.$(date +%Y%m%d_%H%M%S)"
        fi
    fi
    
    # Add shell configuration with conditional checks
    cat >> "$rc_file" << 'EOFSTART'

# ---- Starship ----
EOFSTART
    echo "$init_cmd" >> "$rc_file"
    
    cat >> "$rc_file" << 'EOF'

# ---- Zoxide (only if installed) ----
if command -v zoxide &> /dev/null; then
    eval "$(zoxide init zsh)"
    alias cd="z"
fi

# ---- Aliases ----
if command -v eza &> /dev/null; then
    alias ls="eza --icons=always"
fi

# ---- Atuin (better history) ----
export PATH="$HOME/.atuin/bin:$PATH"
if command -v atuin &> /dev/null; then
    eval "$(atuin init zsh)"
fi

# ---- History ----
HISTSIZE=1000
SAVEHIST=1000
EOF

    # Add zsh plugins for zsh
    if [[ "$CURRENT_SHELL" == "zsh" ]]; then
        cat >> "$rc_file" << 'EOF'

# ---- Autosuggestions ----
[ -f "$HOME/.zsh/zsh-autosuggestions/zsh-autosuggestions.zsh" ] && source "$HOME/.zsh/zsh-autosuggestions/zsh-autosuggestions.zsh"

# ---- Syntax Highlighting (must be at the end) ----
[ -f "$HOME/.zsh/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh" ] && source "$HOME/.zsh/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh"
EOF
    fi

    print_success "Shell configured: $rc_file"
}

case "$CURRENT_SHELL" in
    zsh)
        configure_shell "$HOME/.zshrc" 'eval "$(starship init zsh)"'
        ;;
    bash)
        configure_shell "$HOME/.bashrc" 'eval "$(starship init bash)"'
        ;;
    fish)
        mkdir -p "$HOME/.config/fish"
        FISH_CONFIG="$HOME/.config/fish/config.fish"
        
        if [ -f "$FISH_CONFIG" ]; then
            echo ""
            read -p "$(echo -e "${YELLOW}[QUESTION]${NC} $FISH_CONFIG already exists. Reset it? [y/N] ")" -n 1 -r
            echo ""
            if [[ $REPLY =~ ^[Yy]$ ]]; then
                cp "$FISH_CONFIG" "$FISH_CONFIG.backup.$(date +%Y%m%d_%H%M%S)"
                rm "$FISH_CONFIG"
            elif grep -q "starship init" "$FISH_CONFIG" 2>/dev/null; then
                echo "Already configured, skipping..."
                break
            fi
        fi
        
        cat >> "$FISH_CONFIG" << 'EOF'

# ---- Starship ----
starship init fish | source

# ---- Zoxide (must be before alias) ----
zoxide init fish | source

# ---- Aliases (after zoxide init so 'z' command exists) ----
alias ls="eza --icons=always"
alias cd="z"

# ---- Atuin ----
atuin init fish | source
EOF
        print_success "Shell configured: $FISH_CONFIG"
        ;;
esac

# ============================================
# STEP 12: Done
# ============================================
echo ""
echo "[12/12] Finishing up..."

echo ""
echo "=============================================="
echo -e "${GREEN}Setup Complete!${NC}"
echo "=============================================="
echo ""
echo "Installed:"
echo "  ✓ FiraCode Nerd Font"
[[ "$OS" == "macos" ]] && echo "  ✓ Alacritty (with coolnight theme)"
echo "  ✓ Starship (Bracketed Segments preset)"
echo "  ✓ eza (better ls)"
echo "  ✓ zoxide (better cd)"
echo "  ✓ atuin (better history)"
echo "  ✓ tmux + tpm"
[[ "$CURRENT_SHELL" == "zsh" ]] && echo "  ✓ zsh-syntax-highlighting"
[[ "$CURRENT_SHELL" == "zsh" ]] && echo "  ✓ zsh-autosuggestions"
echo ""
echo "Config files:"
echo "  ~/.config/starship.toml"
[[ "$OS" == "macos" ]] && echo "  ~/.config/alacritty/alacritty.toml"
echo "  ~/.tmux.conf"
echo ""
echo "Next steps:"
echo "  1. Restart terminal or: exec $CURRENT_SHELL"
[[ "$OS" != "macos" ]] && echo "  2. Set terminal font to 'FiraCode Nerd Font'"
echo "  3. In tmux: prefix + Shift-I to install plugins"
echo ""
echo "Customize: https://starship.rs/config/"
echo ""
