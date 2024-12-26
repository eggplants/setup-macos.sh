#!/usr/bin/env zsh

set -eux

if ! [[ -f ~/.sec.key ]]; then
  echo "need: ~/.sec.key"
  exit 1
fi

if ! [[ -f ~/.Brewfile ]]; then
  echo "need: ~/.Brewfile"
  exit 1
fi

cd ~
mkdir -p .config
mkdir -p .gnupg
mkdir -p prog
mkdir -p _setup
pushd _setup

# Setting > Privacy & Security > Security > Allow application from "Anywhere"
sudo spctl --master-disable || :

sudo xcodebuild -license || :

if [[ "$(uname -m)" = 'arm64' ]]; then
  sudo softwareupdate --install-rosetta
fi

/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
if ! command -v brew &>/dev/null; then
  echo >> /Users/eggplants/.zprofile
  echo 'eval "$('"$(brew --prefix)"'/bin/brew shellenv)"' >> /Users/eggplants/.zprofile
  eval 'eval "$('"$(brew --prefix)"'/bin/brew shellenv)"'
fi
brew bundle --global
brew reinstall git nano

# import key
if ! gpg --list-keys | grep -qE '^ *EE3A'; then
  export GPG_TTY="$(tty)"
  export SSH_AUTH_SOCK="$(gpgconf --list-dirs agent-ssh-socket)"
  echo "pinentry-program $(which pinentry-mac)" >~/.gnupg/gpg-agent.conf
  echo enable-ssh-support >> ~/.gnupg/gpg-agent.conf
  touch ~/.gnupg/sshcontrol
  chmod 600 ~/.gnupg/*
  chmod 700 ~/.gnupg
  gpgconf --kill gpg-agent
  sleep 3s
  cat ~/.sec.key | gpg --allow-secret-key --import
  gpg --list-key --with-keygrip | grep -FA1 '[SA]' | awk -F 'Keygrip = ' '$0=$2' >> ~/.gnupg/sshcontrol
  gpg-connect-agent updatestartuptty /bye
  # `gpg --export-ssh-key w10776e8w@yahoo.co.jp > ssh.pub` and copy to server's ~/.ssh/authorized_keys
fi

if ! [[ -f ~/.gitconfig ]]; then
  gh auth login -p https -h gitHub.com -w <<<y
  git_email="$(
    gpg --list-keys | grep -Em1 '^uid' |
      rev | cut -f1 -d ' ' | tr -d '<>' | rev
  )"
  git config --global commit.gpgsign true
  git config --global core.editor nano
  git config --global gpg.program "$(which gpg)"
  git config --global help.autocorrect 1
  git config --global pull.rebase false
  git config --global push.autoSetupRemote true
  git config --global rebase.autosquash true
  git config --global user.email "$git_email"
  git config --global user.name eggplants
  git config --global user.signingkey "$(
    gpg --list-secret-keys | tac | grep -m1 -B1 '^sec' | head -1 | awk '$0=$1'
  )"
  cb_prefix="url.git@codeberg.org:"
  git config --global --remove-section "$gb_prefix" || :
  git config --global "$cb_prefix".pushInsteadOf "git://codeberg.org/"
  git config --global --add "$cb_prefix".pushInsteadOf "https://codeberg.org/"
fi

if ! [[ -d ~/.nano ]]; then
  git clone --depth 1 --single-branch 'https://github.com/serialhex/nano-highlight' ~/.nano
fi
cat <<'A' >~/.nanorc
include "~/.nano/*.nanorc"

set autoindent
set constantshow
set linenumbers
set tabsize 4
set softwrap

# Color
set titlecolor white,red
set numbercolor white,blue
set selectedcolor white,green
set statuscolor white,green
A

# mise
if ! grep -q 'mise activate' ~/.zshrc; then
  mise_path="$(which mise)"
  echo 'eval "$('"$mise_path"' activate bash)"' >>~/.bashrc
  echo 'eval "$('"$mise_path"' activate zsh)"' >>~/.zshrc
  eval 'eval "$('"$mise_path"' activate zsh)"'
fi

# python
if ! mise which python -q &>/dev/null; then
  mise use --global python@latest
  pip install pipx
  pipx ensurepath
  export PATH="$HOME/.local/bin:$PATH"
  pipx install getjump poetry yt-dlp
  poetry self add poetry-version-plugin
fi

# ruby
if ! mise which ruby -q &>/dev/null; then
  mise use --global ruby@latest
fi

# rust
if ! command -v rustc 2>/dev/null; then
  curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
fi

# node
if ! mise which node -q &>/dev/null; then
  mise use --global node@latest
fi

# go
if ! mise which go -q &>/dev/null; then
  mise use --global go@latest
fi

# lisp
command -v sbcl 2>/dev/null || ros install sbcl-bin

# alacritty-theme
if ! [[ -f ~/.config/alacritty/alacritty.toml ]]; then
  mkdir -p ~/.config/alacritty
  curl -o- 'https://codeload.github.com/alacritty/alacritty-theme/tar.gz/refs/heads/master' |
    tar xzf - alacritty-theme-master/themes
  mv alacritty-theme-master ~/.config/alacritty

  nf_font='HackGen Console NF'
  cat <<A >~/.config/alacritty/alacritty.toml
[font]
size = 10.0

[font.bold]
family = "HackGen Console NF"
style = "Bold"

[font.bold_italic]
family = "HackGen Console NF"
style = "Bold Italic"

[font.italic]
family = "HackGen Console NF"
style = "Italic"

[font.normal]
family = "HackGen Console NF"
style = "Regular"

[general]
import = [
  "/Users/eggplants/.config/alacritty/alacritty-theme-master/themes/flexoki.toml",
]
A
fi

# sheldon
sheldon init --shell zsh <<<y
sheldon add --github zdharma/fast-syntax-highlighting fast-syntax-highlighting
sheldon add --github zdharma-continuum/history-search-multi-word history-search-multi-word
sheldon add --github zsh-users/zsh-autosuggestions zsh-autosuggestions
sheldon add --github zsh-users/zsh-completions zsh-completions
sheldon add --use async.zsh pure.zsh --github sindresorhus/pure pure

cat <<'A' >>~/.zshrc
eval "$(sheldon source)"
eval "$(zellij setup --generate-auto-start zsh)"

# if (which zprof > /dev/null) ;then
#   zprof | less
# fi
A

# zsh
[[ "$SHELL" = "$(which zsh)" ]] || chsh -s "$(which zsh)"
cat <<'A' >.zshrc.tmp
#!/usr/bin/env zsh

# load zprofile
[[ -f ~/.zprofile ]] && source ~/.zprofile

# completion
type brew &>/dev/null && FPATH="$(brew --prefix)/share/zsh/site-functions:${FPATH}"
autoload -U compinit
if [ "$(find ~/.zcompdump -mtime 1)" ] ; then
    compinit -u
fi
compinit -uC
zstyle ':completion:*' menu select

# enable opts
setopt correct
setopt autocd
setopt nolistbeep
setopt aliasfuncdef
setopt appendhistory
setopt histignoredups
setopt sharehistory
setopt extendedglob
setopt incappendhistory
setopt interactivecomments
setopt prompt_subst

unsetopt nomatch

# alias
alias ll='ls -lGF --color=auto'
alias ls='ls -GF --color=auto'

# save cmd history up to 100k
HISTFILE="$HOME/.zsh_history"
HISTSIZE=100000
SAVEHIST=100000
HISTFILESIZE=2000
bindkey '^[[A' up-line-or-search
bindkey '^[[B' down-line-or-search

# enable less to show bin
[ -x /usr/bin/lesspipe ] && eval "$(SHELL=/bin/sh lesspipe)"

# enable colorized prompt
case "$TERM" in
  xterm-color | *-256color) color_prompt=yes ;;
esac

# enable colorized ls
export LSCOLORS=gxfxcxdxbxegedabagacag
export LS_COLORS='di=36;40:ln=35;40:so=32;40:pi=33;40:ex=31;40:bd=34;46:cd=34;43:su=30;41:sg=30;46:tw=30;42:ow=30;46'
zstyle ':completion:*:default' list-colors "${(s.:.)LS_COLORS}"

export MANPATH="/usr/local/opt/coreutils/libexec/gnuman:$MANPATH"
export MANPATH="/usr/local/opt/findutils/libexec/gnuman:$MANPATH"
export MANPATH="/usr/local/opt/gnu-sed/libexec/gnuman:$MANPATH"
export MANPATH="/usr/local/opt/gnu-tar/libexec/gnuman:$MANPATH"
export MANPATH="/usr/local/opt/grep/libexec/gnuman:$MANPATH"
export PATH="/usr/local/opt/coreutils/libexec/gnubin:$PATH"
export PATH="/usr/local/opt/findutils/libexec/gnubin:$PATH"
export PATH="/usr/local/opt/gawk/libexec/gnubin:$PATH"
export PATH="/usr/local/opt/gnu-sed/libexec/gnubin:$PATH"
export PATH="/usr/local/opt/gnu-tar/libexec/gnubin:$PATH"
export PATH="/usr/local/opt/grep/libexec/gnubin:$PATH"
export PATH="$(brew --prefix)/bin:$PATH"
export PATH="$(brew --prefix)/sbin:$PATH"
export PATH="$PATH:$HOME/.local/bin"
export PERLLIB="/Library/Developer/CommandLineTools/usr/share/git-core/perl:$PERLLIB"

unset SSH_AGENT_PID
if [ "${gnupg_SSH_AUTH_SOCK_by:-0}" -ne $$ ]; then
  export SSH_AUTH_SOCK="$(gpgconf --list-dirs agent-ssh-socket)"
fi
export GPG_TTY="$(tty)"
gpg-connect-agent updatestartuptty /bye >/dev/null
A
cat ~/.zshrc >>.zshrc.tmp
mv .zshrc.tmp ~/.zshrc

cat <<'A' | sed 's;@brew_path@;'"$(brew --prefix)"'/bin/brew;' >.zshenv.tmp
#!/usr/bin/env zsh

function brew() {
  @brew_path@ "$@"
  if [[ "$1" =~ '^(install|remove|tap|uninstall)$' ]]; then
    @brew_path@ bundle dump --force --global
  fi
}

function shfmt() {
  shfmt -i 4 -l -w "$@"
}
A
cat ~/.zshenv >>.zshenv.tmp
mv .zshenv.tmp ~/.zshenv

rm ~/.sec.key
popd
rm -rf _setup
