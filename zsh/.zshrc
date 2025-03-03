# Copyright 2006-2014 Joseph Block <jpb@apesseekingknowledge.net>
#
# BSD licensed, see LICENSE.txt

# Set zsh syntax highlighters
export ZSH_HIGHLIGHT_HIGHLIGHTERS=(main brackets pattern cursor)
export ZSH_HIGHLIGHT_PATTERNS=('rm -rf *' 'fg=white,bold,bg=red')

# Set to this to use case-sensitive completion
# CASE_SENSITIVE="true"

# Uncomment following line if you want to disable colors in ls
# DISABLE_LS_COLORS="true"

# Uncomment following line if you want to disable autosetting terminal title.
# DISABLE_AUTO_TITLE="true"

# Uncomment following line if you want red dots to be displayed while waiting for completion
export COMPLETION_WAITING_DOTS="true"

# Correct spelling for commands
setopt correct
# turn off the infernal correctallf for filenames
unsetopt correctall

# Fun with SSH
if [ $(ssh-add -l | grep -c "The agent has no identities." ) -eq 1 ]; then
  if [[ "$(uname -s)" == "Darwin" ]]; then
    # We're on OS X. Try to load our ssh keys using pass phrases stored in
    # the OSX keychain.
    ssh-add -k
  else
    ssh-add ~/.ssh/id_dsa
    ssh-add ~/.ssh/id_rsa
  fi
fi

if [ -f ~/.ssh/id_rsa ]; then
  if [ $(ssh-add -l | grep -c ".ssh/id_rsa" ) -eq 0 ]; then
    ssh-add ~/.ssh/id_rsa
  fi
fi

if [ -f ~/.ssh/id_dsa ]; then
  if [ $(ssh-add -L | grep -c ".ssh/id_dsa" ) -eq 0 ]; then
    ssh-add ~/.ssh/id_dsa
  fi
fi

# Configure antigen.
# Path to antigen checkout
ANTIGEN=${HOME}/antigen

if [ ! -d "${ANTIGEN}" ]; then
  git clone git@github.com:zsh-users/antigen.git ~/antigen
fi

source "$ANTIGEN/antigen.zsh"

antigen use oh-my-zsh

antigen bundle unixorn/autoupdate-antigen.zshplugin
antigen bundle zsh-users/zsh-syntax-highlighting
antigen-bundle zsh-users/zsh-history-substring-search
antigen bundle unixorn/rake-completion.zshplugin

antigen bundles <<EOBUNDLES
gem
git
github
history-substring-search
knife
python
rake
rsync
ruby
screen
textmate
thor
vagrant
virtualenvwrapper
EOBUNDLES

if [[ "$(uname -s)" == "Darwin" ]]; then
  antigen bundle osx
fi

# Get the powerline patched fonts from https://github.com/Lokaltog/powerline-fonts
# if you want the pretty branch icon in your prompt
#antigen theme https://gist.github.com/016e035175cbf0059876.git jpb-segmented

antigen theme https://github.com/caiogondim/bullet-train-oh-my-zsh-theme bullet-train

antigen apply

# set some history options
setopt append_history
setopt extended_history
setopt hist_expire_dups_first
setopt hist_ignore_all_dups
setopt hist_ignore_dups
setopt hist_ignore_space
setopt hist_reduce_blanks
setopt hist_save_no_dups
setopt hist_verify
# Share your history across all your terminal windows
setopt share_history
#setopt noclobber

#set some more options
setopt pushd_ignore_dups
#setopt pushd_silent

# Keep a ton of history.
HISTSIZE=100000
SAVEHIST=100000
HISTFILE=~/.zsh_history
export HISTIGNORE="ls:cd:cd -:pwd:exit:date:* --help"

# Long running processes should return time after they complete
REPORTTIME=2
TIMEFMT="%U user %S system %P cpu %*Es total"

# Customize to your needs...
# Stuff that works on bash or zsh
if [ -r ~/.sh_aliases ]; then
  source ~/.sh_aliases
fi

# Stuff only tested on zsh, or explicitly zsh-specific
if [ -r ~/.zsh_aliases ]; then
  source ~/.zsh_aliases
fi

# Path nonsense
PATH=/sbin:/usr/sbin:/usr/local/bin:/usr/local/sbin:$PATH

# Conditional PATH additions

for path_candidate in /opt/local/sbin \
  /opt/local/bin \
  /Applications/Xcode.app/Contents/Developer/usr/bin \
  /usr/local/share/npm/bin \
  ~/bin/ec2-api/bin \
  ~/.cabal/bin \
  ~/.rbenv/bin \
  ~/bin \
  ~/bin/iamcli-current/bin \
  ~/bin/sysadmin-util \
  ~/nta/packer \
  ~/src/gocode/bin
do
  if [ -d ${path_candidate} ]; then
    export PATH=${PATH}:${path_candidate}
  fi
done

export LOCATE_PATH=/var/db/locate.database

# Load AWS credentials
if [ -f ~/.aws/aws_variables ]; then
  source ~/.aws/aws_variables
fi

# JAVA setup - needed for iam-* tools
if [ -d /Library/Java/Home ];then
  export JAVA_HOME=/Library/Java/Home
fi

if [[ "$(uname -s)" == "Darwin" ]]; then
  # We're on osx
  if [ -f .osx_aliases ]; then
    source .osx_aliases
  fi
  if [ -d $HOME/.osx_aliases.d ]; then
    for alias_file in $HOME/.osx_aliases.d/*
    do
      source $alias_file
    done
  fi
fi

# deal with screen, if we're using it - courtesy MacOSXHints.com
# Login greeting ------------------
if [ "$TERM" = "screen" -a ! "$SHOWED_SCREEN_MESSAGE" = "true" ]; then
  detached_screens=$(screen -list | grep Detached)
  if [ ! -z "$detached_screens" ]; then
    echo "+---------------------------------------+"
    echo "| Detached screens are available:       |"
    echo "$detached_screens"
    echo "+---------------------------------------+"
  fi
fi

# Check for a detached screen session and reconnect. If there are more than
# one, list them instead.
#
# Based on http://ptone.com/dablog/2009/02/getting-the-screen-religion/
AM_I_REMOTE=$(who am i | grep -c ")$")
if [ $AM_I_REMOTE -gt 0 ]; then
  SCREENS=$(screen -list | head -1 | awk '{ print $1 }')
  if [ $SCREENS = 'No' ]; then
    screen -t Main
  else
    SCREENCOUNT=$(screen -list | tail -2 | head -1 | awk '{ print $1 }')
    if [ $SCREENCOUNT -eq 1 ]; then
      screen -r
    else
      CANDIDATE_SCREEN=$(screen -list | grep "(Detached)" | head -1 | awk -F "." '{print $1}')
      DETACHED_SCREENCOUNT=$(screen -list | grep -c "(Detached)")
      if [ $DETACHED_SCREENCOUNT -gt 0 ];then
        screen -R "$CANDIDATE_SCREEN"
      fi
    fi
  fi
fi

# I use grc to colorize some command output for clarity.
# brew install grc to check it out.
if [ -f /usr/local/etc/grc.bashrc ]; then
  source "$(brew --prefix)/etc/grc.bashrc"
  alias ping5='colourify ping -c 5'
else
  alias ping5='ping -c 5'
fi

# speed up autocomplete, force prefix mapping
zstyle ':completion:*' accept-exact '*(N)'
zstyle ':completion:*' use-cache on
zstyle ':completion:*' cache-path ~/.zsh/cache
zstyle -e ':completion:*:default' list-colors 'reply=("${PREFIX:+=(#bi)($PREFIX:t)*==34=34}:${(s.:.)LS_COLORS}")';

# load any custom zsh completions we've installed
if [ -d ~/.zsh-completions ]; then
  for completion in ~/.zsh-completions/*
  do
    source "$completion"
  done
fi

echo
echo "Current SSH Keys:"
ssh-add -l
echo

# Make it easy to append your own customizations that override the above
if [ -f ~/.zshrc.local ]; then
  source .zshrc.local
fi

# In case a plugin adds a redundant path entry, remove duplicate entries
# from PATH
#
# This snippet is from Mislav Marohnić <mislav.marohnic@gmail.com>'s
# dotfiles repo at https://github.com/mislav/dotfiles

dedupe_path() {
  typeset -a paths result
  paths=($path)

  while [[ ${#paths} -gt 0 ]]; do
    p="${paths[1]}"
    shift paths
    [[ -z ${paths[(r)$p]} ]] && result+="$p"
  done

  export PATH=${(j+:+)result}
}

dedupe_path
