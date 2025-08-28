#!/bin/bash

# TENHA MUITO CUIDADO COM ESSE SCRIPT, ELE NÃO VAI TE PERDOAR.

# Funções para printar mensagens coloridas de forma legível
loginfo() {
  local BLUE='\033[1;34m'
  local RESET='\033[0m'
  printf "🔵 ${BLUE}%s${RESET}\n" "$1"
}

logsuccess() {
  local GREEN='\033[1;32m'
  local RESET='\033[0m'
  printf "🟢 ${GREEN}%s${RESET}\n" "$1"
}

logerror() {
  local RED='\033[1;31m'
  local RESET='\033[0m'
  printf "🔴 ${RED}%s${RESET}\n" "$1"
}

# garante que o script pare em caso de erro
set -e

# Vamos tentar descobrir o sistema operacional
OP_SYSTEM=""

if [ "$(uname -s)" == "Linux" ]; then
    echo "This system is Linux."
    if [ -f /etc/os-release ]; then
        . /etc/os-release
        if [ "$ID" == "arch" ]; then
            OP_SYSTEM="arch" # aqui é arch
        else
            # Aqui não sei qual sistema é, mas é Linux
            logerror "This is another Linux distribution: $PRETTY_NAME"
        fi
    elif command -v lsb_release &> /dev/null; then
        if lsb_release -d | grep -q "Arch Linux"; then
            OP_SYSTEM="arch" # aqui também é arch
        fi
    fi
else
  # Eu não vou rodar se não for Arch
  logerror "It is not safe to run this script on your system."
  exit 1
fi

if [[ "$OP_SYSTEM" == "arch" ]]; then

  # Aqui é Arch Linux, então pacman nos pacotes
  loginfo "Your system is Arch Linux, updating packages..."
  sudo pacman -Suuy --noconfirm
  
  loginfo "Installing apps..."
  sudo pacman -Suuy --noconfirm \
	  openssl git curl wget bat eza tmux neovim ghostty ffmpeg htop 7zip tree \
	  python nodejs \
	  ttf-jetbrains-mono ttf-jetbrains-mono-nerd \
	  ttf-fira-code ttf-firacode-nerd ttf-fira-mono ttf-fira-sans \
	  zsh

  chsh -s $(which zsh)
  
else
  # Eu tenho medo de rodar isso noutro sistema que não testei
  # Mas lendo aqui você pode fazer tudo manualmente
  logerror "Wrong system, sorry!"
  exit 1
fi

# --- Zsh e Oh My Zsh ---
loginfo "Configurando Zsh e Oh My Zsh..."
if [ ! -d "$HOME/.oh-my-zsh" ]; then
  loginfo "Instalando Oh My Zsh..."
  /bin/sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
else
  loginfo "Oh My Zsh já está instalado."
fi

# Instala plugins do Zsh
ZSH_CUSTOM="$HOME/.oh-my-zsh/custom"
loginfo "🔌 Instalando plugins do Zsh..."
if [ ! -d "${ZSH_CUSTOM}/plugins/zsh-autosuggestions" ]; then
  git clone https://github.com/zsh-users/zsh-autosuggestions "${ZSH_CUSTOM}/plugins/zsh-autosuggestions"
fi
if [ ! -d "${ZSH_CUSTOM}/plugins/zsh-syntax-highlighting" ]; then
  git clone https://github.com/zsh-users/zsh-syntax-highlighting.git "${ZSH_CUSTOM}/plugins/zsh-syntax-highlighting"
fi

# --- Configuração do Neovim com Lazy.nvim ---
loginfo "🐘 Configurando Neovim e Lazy.nvim..."
LAZY_PATH="$HOME/.local/share/nvim/lazy/lazy.nvim"
if [ ! -d "$LAZY_PATH" ]; then
  loginfo "Instalando o gerenciador de plugins Lazy.nvim..."
  git clone https://github.com/folke/lazy.nvim.git --filter=blob:none "$LAZY_PATH"
fi

# --- Gerenciador de Plugins do Tmux (TPM) ---
loginfo "🔄 Instalando TPM para Tmux..."
if [ ! -d "$HOME/.tmux/plugins/tpm" ]; then
  git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm
fi

if ! command -v pyenv &> /dev/null; then
  # Pyenv e uv
  loginfo "Installing Pyenv and uv..."
  rm -Rf "${HOME}/.pyenv"
  curl -fsSL https://pyenv.run | bash
  #export PATH=”$HOME/.pyenv/bin:$PATH” eval “$(pyenv init –path)” eval “$(pyenv init -)” eval “$(pyenv virtualenv-init -)”
else
  loginfo "Pyenv já instalado..."
fi

if ! command -v uv &> /dev/null; then
  # UV 
  loginfo "Installing uv..."
  curl -LsSf https://astral.sh/uv/install.sh | sh
else
  loginfo "UV já instalado..."
fi

if ! command -v nvm &> /dev/null; then
  # NVM
  rm -Rf "${HOME}/.nvm"
  curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.3/install.sh | bash
else
  loginfo "NVM já instalado..."
fi

echo -e "
[1;33mATENÇÃO: Passos manuais necessários:[0m"
echo ""
echo "ABRA OUTRO TERMINAL - NÃO USE ESSA INSTÂNCIA"
echo ""
echo "1. Execute 'nvm install --lts'"
echo "2. Execute 'nvm install-latest-npm'"
echo "3. Execute 'npm i -g prettier'"
echo "4. Execute 'pyenv install 3.13.5' (ou versões mais novas)"
echo "5. Execute 'pyenv global 3.13.5' (ou versões mais novas)"
echo "6. Execute 'uv tool install pyright'"
echo "7. Execute 'uv tool install ruff'"
echo ""
read -p "Ao terminar as tarefas acima, pressione qualquer tecla para continuar..."

# --- Criação de Symlinks ---
loginfo "🔗 Criando symlinks para os arquivos de configuração..."

# Cria o diretório ~/.config se não existir
mkdir -p "$HOME/.config"

# Zsh
rm -Rf "$HOME/.zshrc"
ln -sf "$HOME/dotfiles/zsh/.zshrc" "$HOME/.zshrc"

rm -Rf "$HOME/.zprofile"
ln -sf "$HOME/dotfiles/zsh/.zprofile" "$HOME/.zprofile"

rm -Rf "$ZSH_CUSTOM/themes/omtheme.zsh-theme"
ln -sf "$HOME/dotfiles/zsh/config/omtheme.zsh-theme" "$ZSH_CUSTOM/themes/omtheme.zsh-theme"

# Git
rm -Rf "$HOME/.gitconfig"
ln -sf "$HOME/dotfiles/git/.gitconfig" "$HOME/.gitconfig"

# Tmux
rm -Rf "$HOME/.tmux.conf"
ln -sf "$HOME/dotfiles/tmux/.tmux.conf" "$HOME/.tmux.conf"

# Vim (para compatibilidade)
rm -Rf "$HOME/.vimrc"
ln -sf "$HOME/dotfiles/vim/.vimrc" "$HOME/.vimrc"

# Neovim
rm -Rf "$HOME/.config/nvim"
ln -sf "$HOME/dotfiles/nvim" "$HOME/.config/nvim"

# Ghostty
rm -Rf "$HOME/.config/ghostty"
ln -sf "$HOME/dotfiles/ghostty" "$HOME/.config/ghostty"

echo -e "
[1;33mATENÇÃO: Passos manuais necessários:[0m"
echo ""
echo "ABRA OUTRO TERMINAL (NOVAMENTE) - NÃO USE ESSA INSTÂNCIA"
echo ""
echo "1. Abra o Neovim ('nvim') para que o Lazy.nvim possa instalar todos os plugins."
echo "2. Inicie o Tmux e pressione 'prefix + I' (Ctrl+b + I) para instalar os plugins do TPM."
echo "3. Reinicie seu terminal para que todas as alterações tenham efeito."
echo ""
read -p "Ao terminar as tarefas acima, pressione qualquer tecla para continuar..."

# --- Finalização ---
echo ""
loginfo "✅ Script de instalação concluído!"
