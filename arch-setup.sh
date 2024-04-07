#!/bin/bash

# Function to print colorful messages
print_color() {
    # $1: Message, $2: Color
    case $2 in
        "red") echo -e "\033[0;31m$1\033[0m" ;;
        "green") echo -e "\033[0;32m$1\033[0m" ;;
        "yellow") echo -e "\033[0;33m$1\033[0m" ;;
        "blue") echo -e "\033[0;34m$1\033[0m" ;;
        *) echo "$1" ;;
    esac
}

# Function to check if directory exists and clone if not
clone_if_not_exist() {
    local directory="$1"
    local repo_url="$2"
    if [ ! -d "$directory" ]; then
        print_color "Cloning $repo_url to $directory..." "blue"
        if ! git clone "$repo_url" "$directory"; then
            print_color "Failed to clone $repo_url. Exiting." "red"
            exit 1
        fi
    else
        print_color "$directory already exists. Skipping clone." "green"
    fi
}

# Function to check if package is installed
check_installed() {
    local missing_packages=()
    for package in "$@"; do
        if ! (pacman -Q "$package" &>/dev/null || yay -Q "$package" &>/dev/null); then
            missing_packages+=("$package")
        fi
    done

    if [ ${#missing_packages[@]} -gt 0 ]; then
        print_color "Installing missing packages with yay..." "blue"
        yay -S --noconfirm "${missing_packages[@]}" || {
            print_color "Failed to install some packages. Exiting." "red"
            exit 1
        }
    else
        print_color "All required yay packages are already installed. Skipping." "green"
    fi
}

# Function to install yay if not installed
install_yay() {
    if ! command -v yay &>/dev/null; then
        print_color "Installing yay package manager..." "yellow"
        if ! sudo pacman -S --needed --noconfirm git base-devel; then
            print_color "Failed to install prerequisites for yay. Exiting." "red"
            exit 1
        fi
        if ! git clone https://aur.archlinux.org/yay.git /tmp/yay; then
            print_color "Failed to clone yay repository. Exiting." "red"
            exit 1
        fi
        if ! (cd /tmp/yay && makepkg -si --noconfirm); then
            print_color "Failed to install yay. Exiting." "red"
            exit 1
        fi
        rm -rf /tmp/yay
    fi
}

# Install yay if not installed
print_color "Checking if yay is installed..." "blue"
install_yay

# List of required packages (sorted alphabetically)
required_packages=(
    "adb" "android-tools" "android-udev" "arj" "aria2" "axel"
    "base-devel" "battop" "bc" "bison" "brotli" "cabextract" "ccache"
    "clang" "cmake" "cpio" "curl" "dbus" "detox" "dtc" "dpkg"
    "file-roller" "flex" "flatpak" "freedownloadmanager"
    "gcc" "gcc-libs" "gawk" "git" "github-cli" "go" "glibc"
    "htop" "inetutils" "jdk21-openjdk" "jq" "less" "libelf"
    "libxcrypt-compat" "lineageos-devel" "lzip" "lz4" "make" "man-pages"
    "mlocate" "multilib-devel" "neofetch" "neovim" "ninja" "noto-fonts-cjk"
    "noto-fonts-extra" "ncurses" "openssh" "openssl" "p7zip" "python-pip"
    "python-setuptools" "python3" "repo" "rclone" "rsync" "screen" "sharutils"
    "slack-desktop" "speedtest-cli" "systemd" "telegram-desktop" "tmate" "tmux"
    "unace" "unrar" "uudeview" "util-linux" "visual-studio-code-bin" "wget"
    "xml2" "z3" "zsh"
)

# Check which required packages are not installed
check_installed "${required_packages[@]}"

# Git configuration
if [[ $USER == "kunmun" ]]; then
    print_color "Configuring Git for user 'kunmun'..." "blue"
    git config --global user.email "kunmun@aospa.co"
    git config --global user.name "Kunmun"
    git config --global credential.helper cache
    git config --global credential.helper 'cache --timeout=9999999'
    git config --global gpg.format ssh
    git config --global user.signingkey ~/.ssh/id_ed25519.pub
    git config --global commit.gpgsign true
    print_color "Git configuration done." "green"
fi

# Install patched Nerd Fonts if not already installed
if [ ! -d "$HOME/.fonts" ]; then
    print_color "Installing patched Nerd Fonts..." "blue"
    mkdir -p ~/.fonts
    if ! wget "https://github.com/ryanoasis/nerd-fonts/releases/download/v3.1.0/JetBrainsMono.zip" -O JetBrainsMono.zip; then
        print_color "Failed to download Nerd Fonts. Exiting." "red"
        exit 1
    fi
    if ! unzip JetBrainsMono.zip -d ~/.fonts/; then
        print_color "Failed to unzip Nerd Fonts. Exiting." "red"
        exit 1
    fi
    rm JetBrainsMono.zip
    if ! fc-cache -fv; then
        print_color "Failed to refresh font cache. Exiting." "red"
        exit 1
    fi
else
    print_color "Patched Nerd Fonts already installed. Skipping." "green"
fi

# Set default shell to Zsh
print_color "Setting default shell to Zsh..." "blue"
chsh -s /bin/zsh "$USER"

# Install Oh My Zsh
print_color "Installing Oh My Zsh..." "blue"
sh -c "$(curl -fsSL https://raw.github.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"

# Check and clone zsh-autosuggestions if not exists
clone_if_not_exist "$HOME/.oh-my-zsh/custom/zsh-autosuggestions" "https://github.com/zsh-users/zsh-autosuggestions.git"

# Check and clone zsh-syntax-highlighting if not exists
clone_if_not_exist "$HOME/.oh-my-zsh/custom/zsh-syntax-highlighting" "https://github.com/zsh-users/zsh-syntax-highlighting.git"

# Install Starship prompt
print_color "Installing Starship prompt..." "blue"
if ! curl -sS https://starship.rs/install.sh | sh; then
    print_color "Failed to install Starship. Exiting." "red"
    exit 1
fi

# Setup Gerrit commit-msg hooks
print_color "Setting up Gerrit commit-msg hooks..." "blue"
git config --global init.templatedir '~/.git-templates'
mkdir -p ~/.git-templates/hooks
if ! curl -Lo ~/.git-templates/hooks/commit-msg http://gerrit.aospa.co/tools/hooks/commit-msg; then
    print_color "Failed to download Gerrit commit-msg hook. Exiting." "red"
    exit 1
fi
chmod 755 ~/.git-templates/hooks/commit-msg
echo 'Change-id hooks are been setup successfully'

# Install PixelDrain
print_color "Installing PixelDrain (pdup)..." "blue"
if ! sudo wget https://raw.githubusercontent.com/Fornax96/pdup/master/pdup -O "/usr/local/bin/pdup"; then
    print_color "Failed to download pdup. Exiting." "red"
    exit 1
fi
if ! sudo chmod +x "/usr/local/bin/pdup"; then
    print_color "Failed to set permissions for pdup. Exiting." "red"
    exit 1
fi

print_color "Setup complete." "green"

# Add Starship initialization to ~/.zshrc if the default shell is Zsh and it's not already added
if [ "$(basename "$SHELL")" = "zsh" ]; then
    print_color "Checking if Starship initialization is already in ~/.zshrc..." "blue"
    if ! grep -q "starship init zsh" ~/.zshrc; then
        print_color "Adding Starship initialization to ~/.zshrc..." "blue"
        echo 'eval "$(starship init zsh)"' >> ~/.zshrc
    else
        print_color "Starship initialization already exists in ~/.zshrc. Skipping." "green"
    fi
fi

print_color "All tasks completed successfully." "green"
