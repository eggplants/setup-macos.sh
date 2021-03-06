#!/usr/bin/env bash

set -eux
user="${1-eggplants}"
mail="${2-w10776e8w@yahoo.co.jp}"

/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
brew update
brew tap fumiyas/echo-sd
brew tap gcenx/wine
brew install --cask \
    docker google-chrome google-japanese-ime　iterm2 \
    keybase obs slack visual-studio-code zoom zsh-completions
open /Applications/Docker.app
brew install \
    act binutils byobu cmake coreutils deno diffutils \
    echo-sd emacs feh findutils gawk gh gnu-sed \
    gnu-tar gnupg go grep hadolint imagemagick nodenv ncurses \
    nkf mas mecab mecab mecab-ipadic pinentry-mac pyenv rbenv shellcheck \
    sl spectacle tcl-tk@8.6.12 \
    tmux tree uniutils wget wine-crossover winetricks w3m xquartz yarn
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh
brew reinstall git nano
mas install 1429033973 # runcat

curl https://raw.githubusercontent.com/scopatz/nanorc/master/install.sh | sh

git clone https://github.com/eggplants/dotfiles
cp dotfiles/.{*shrc,nanorc,gitconfig,weather*.sh} ~
chmod +x ~/.weather*.sh

git config --global gpg.program "$(which gpg)"
git config --global credential.helper \
    /usr/local/Cellar/git/*/share/git-core/contrib/credential/netrc/git-credential-netrc.perl
keybase login
mkdir ~/.gnupg
echo "pinentry-program $(which pinentry-mac)" > ~/.gnupg/gpg-agent.conf
chmod 600 ~/.gnupg/*
chmod 700 ~/.gnupg

echo -n "gh-token: "
read -sr pass
cat << A > .netrc
echo machine github.com
echo login $user
password $pass
machine gist.github.com
login $user
password $pass
A

echo -e "5\ny\n" |
    gpg --command-fd 0 \
        --expert --edit-key "$(
            gpg --list-keys |
            sed -n '4s/^  *//p'
        )" trust
gpg -e -r "$mail" ~/.netrc && rm -i "$_"

cat << 'A' >> .zshenv
##### Mac BEGIN #####

export COWPATH="$HOME/usr/share/cows"
export MANPATH="/usr/local/opt/coreutils/libexec/gnuman:$MANPATH"
export MANPATH="/usr/local/opt/findutils/libexec/gnuman:$MANPATH"
export MANPATH="/usr/local/opt/gnu-sed/libexec/gnuman:$MANPATH"
export MANPATH="/usr/local/opt/gnu-tar/libexec/gnuman:$MANPATH"
export MANPATH="/usr/local/opt/grep/libexec/gnuman:$MANPATH"
export PATH="/usr/local/opt/coreutils/libexec/gnubin:$PATH"
export PATH="/usr/local/opt/findutils/libexec/gnubin:$PATH"
export PATH="/usr/local/opt/gnu-sed/libexec/gnubin:$PATH"
export PATH="/usr/local/opt/gnu-tar/libexec/gnubin:$PATH"
export PATH="/usr/local/opt/grep/libexec/gnubin:$PATH"
export PATH="/usr/local/opt/tcl-tk/bin:$PATH"
export PATH="/usr/local/sbin:$PATH"
export PERLLIB="/Library/Developer/CommandLineTools/usr/share/git-core/perl:$PERLLIB"
eval "$(nodenv init -)"
if type brew &>/dev/null; then
  FPATH=$(brew --prefix)/share/zsh-completions:$FPATH
  autoload -Uz compinit
  compinit
fi

##### mac END #####
A

for v in '3.7.12' '3.8.12' '3.9.7' '3.10.0'; do
  env \
    PATH="$(brew --prefix tcl-tk)/bin:$PATH" \
    LDFLAGS="-L$(brew --prefix tcl-tk)/lib" \
    CPPFLAGS="-I$(brew --prefix tcl-tk)/include" \
    PKG_CONFIG_PATH="$(brew --prefix tcl-tk)/lib/pkgconfig" \
    CFLAGS="-I$(brew --prefix tcl-tk)/include" \
    PYTHON_CONFIGURE_OPTS="\
--with-tcltk-includes='-I$(brew --prefix tcl-tk)/include' \
--with-tcltk-libs='-L$(brew --prefix tcl-tk)/lib \
-ltcl8.6 -ltk8.6'" pyenv install "$v"
done
pyenv global "3.9.7"
rbenv install 3.0.0
rbenv install 2.7.4
pyenv global "$_"
nodenv install 17.0.1
nodenv global "$_"

sudo spctl --master-disable

chmod 755 /usr/local/share && rm -f ~/.zcompdump && compinit
