#!/bin/bash
set -u
shopt -s expand_aliases

read -r -d '' USAGE <<'EOF'
Usage dep-setup.sh [-h] [-n] [-f filename] [-g git_repo_path]

for help, run dep-setup.sh -h.
EOF

read -r -d '' HELP <<'EOF'
NAME
  dep-setup.sh -- Set up dependencies

SYNOPSIS
  dep-setup.sh [-h] [-n] [-f filename]

DESCRIPTION
  dep-setup.sh is a script intended to make seting up and maintaining a
  dev system as simple as possible

OPTIONS
  -h
    Display this manual page
  -e/-E
    Disable (-e) or enable (-E) emoji icons in output.
  -c/-C
    Disable (-c) or enable (-C) colorized output.
EOF

# Parse command line arguments, and set up flags.
DISABLE_COLORS=0
DISABLE_EMOJI=0
DRY_RUN=0

parse_args() {
  local source=$1
  shift
  local skip=${1-}
  shift
  args=$(getopt "cCdDeEf:g:hnN" "${source}")
  if [[ $? != 0 ]]; then
    if [[ -z ${skip-} ]]; then
      echo "${USAGE}"
      exit 2
    fi
  fi
  set -- $args

  for i; do
    case "$i" in
    -h)
      echo "${HELP}"
      exit 1
      ;;
    -d)
      DRY_RUN=1
      shift
      ;;
    -D)
      DRY_RUN=0
      shift
      ;;
    -c)
      DISABLE_COLORS=1
      shift
      ;;
    -C)
      DISABLE_COLORS=0
      shift
      ;;
    -e)
      DISABLE_EMOJI=1
      shift
      ;;
    -E)
      DISABLE_EMOJI=0
      shift
      ;;
    --)
      shift
      break
      ;;
    esac
  done
}

#source fun.sh
# Define a function that consumes arguments from STDIN, binds each to a named
# parameter, and evaluates an expression with these bindings.
# E.g.: list 1 2 | lambda x y . '$x + $y' prints "3".
lambda() {

  lam() {
    local arg
    while [[ $# -gt 0 ]]; do
      arg="$1"
      shift
      if [[ $arg = '.' ]]; then
        echo "$@"
        return
      else
        echo "read $arg;"
      fi
    done
  }

  eval $(lam "$@")

}

# Apply lambda to arguments
λ() {
  lambda "$@"
}

# Convert arguments into a newline-delimited list on STDOUT
list() {
  for i in "$@"; do
    echo "$i"
  done
}

# Apply the supplied function to each line of input
map() {
  if [[ $1 != "λ" ]] && [[ $1 != "lambda" ]]; then

    local has_dollar=$(list $@ | grep '\$' | wc -l)

    if [[ $has_dollar -ne 0 ]]; then
      args=$(echo $@ | sed -e 's/\$/\$a/g')
      map λ a . $args
    else
      map λ a . "$@"' $a'
    fi
  else
    local x
    while read x; do
      echo "$x" | "$@"
    done
  fi
}
# end source fun.sh

# Is this OSX or Linux?
if [[ "$(uname)" = "Linux" ]]; then
  INSTALL_ON_LINUX=1
fi

parse_args "$*"

# string formatter
if [[ -t 1 ]]; then
  tty_escape() { printf "\033[%sm" "$1"; }
else
  tty_escape() { :; }
fi

if ((1 == "${DISABLE_COLORS}")); then
  tty_mkbold() { tty_reset ";$1"; }
  tty_underline=""
  tty_green=""
  tty_yellow=""
  tty_red=""
  tty_bold=""
else
  tty_mkbold() { tty_escape "1;$1"; }
  tty_underline="$(tty_escape "4;39")"
  tty_green="(tty_mkbold 92)"
  tty_yellow="(tty_mkbold 93)"
  tty_red="(tty_mkbold 91)"
  tty_bold="(tty_mkbold 39)"
fi

tty_reset="$(tty_escape 0)"

is_dry_run() {
  if ((0 == "${DRY_RUN:-0}")); then return 1; fi
}

colorize() {
  local fmt=$1
  shift
  local spacer=$1
  shift
  local weight=$1
  shift
  list "$@" | map lambda x . 'printf  "${fmt}${spacer}${weight} $x${tty_reset}\n"'
}

mention() {
  if ((1 == "${DISABLE_EMOJI}")); then
    colorize "${tty_green}" ">>>     " "${tty_reset}" "$@"
  else
    colorize "${tty_green}😀 " ">>>     " "${tty_reset}" "$@"
  fi
}

say() {
  if ((1 == "${DISABLE_EMOJI}")); then
    colorize "${tty_green}" ">>>" "${tty_bold}" "$@"
  else
    colorize "${tty_green}😀 " ">>>" "${tty_bold}" "$@"
  fi
}

claim() {
  if ((1 == "${DISABLE_EMOJI}")); then
    colorize "${tty_green}" ">>>" "${tty_bold}" "$@"
  else
    colorize "${tty_green}💯 " ">>>" "${tty_bold}" "$@"
  fi
}

deny() {
  if ((1 == "${DISABLE_EMOJI}")); then
    colorize "${tty_yellow}" ">>>" "${tty_red}" "$@"
  else
    colorize "${tty_yellow}🚫 " ">>>" "${tty_red}" "$@"
  fi
}

warn() {
  if ((1 == "${DISABLE_EMOJI}")); then
    colorize "${tty_yellow}" ">>>" "${tty_yellow}" "$@"
  else
    colorize "${tty_yellow}❗️ " ">>>" "${tty_yellow}" "$@"
  fi
}

abort() {
  if ((1 == "${DISABLE_EMOJI}")); then
    colorize "${tty_red}" ">>>" "${tty_red}" "$@"
  else
    colorize "${tty_red}☠️  " ">>>" "${tty_red}" "$@"
  fi
  exit 1
}

step_banner() {
  echo
  say "$@"
  say "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
}

execute() {
  if is_dry_run; then
    deny "Dry run: would execute $@"
  else
    if ((1 == "${DISABLE_EMOJI}")); then
      echo "${tty_green}>>> ${tty_bold}Running '$@'${tty_reset}"
    else
      echo "${tty_green}⚙️  >>> ${tty_bold}Running '$@'${tty_reset}"
    fi
    if ! "$@"; then
      abort "Command failed:" $(echo "$@" | lambda x . 'printf $x')
    fi
  fi
}

should_install() {
  if [[ $(command -v $1) ]]; then return 1; fi
}

should_brew() {
  local cmd=$1
  local pkg=${2:-${cmd}}
  if [[ $(command -v ${cmd}) ]] || brew info --json=v1 --installed | jq .[].name | grep -q "\<${pkg}\>"; then return 1; fi
}

try_execute() {
  local pred=$1
  shift
  local cmd=$1
  shift
  if $pred; then
    if is_dry_run; then
      deny "Dry run: would execute ${cmd}."
    else
      execute ${cmd}
    fi
  fi
}

try_install() {
  local pred=$1
  shift
  local name=$1
  shift
  local cmd=$1
  shift

  if $pred; then
    warn "We need to install $name before we can continue."

    if is_dry_run; then
      deny "Dry run: would install ${name}."
    else
      if [[ -n "${INSTALL_ON_LINUX-}" ]]; then
        abort "I'm afraid that you are on your own"
      else
        say "We will install $name."
        execute ${cmd}
      fi
    fi
  else
    claim "$name already installed"
  fi
}

try_brew_install() {
  local cmd=$1
  local pkg=${2:-${cmd}}

  try_install "should_brew ${cmd} ${pkg}" "${pkg}" "brew install ${pkg}"
}

open_url() {
  if [[ -z "${OPEN_CMD-}" ]]; then
    if [[ -n "${INSTALL_ON_LINUX-}" ]]; then
      if should_install xdg-open; then
        abort "You must install xdg-open, then try running me again."
      else
        OPEN_CMD='xdg-open'
      fi
    else
      OPEN_CMD='open'
    fi
  fi

  if is_dry_run; then
    deny "Dry run: would open $@"
  else
    ${OPEN_CMD} "$@" &>/dev/null &
    disown
  fi
}

###################################
# Steps to bootstrap a new system #
###################################

read -r -d '' BREW_INSTALL_CMD <<'EOF'
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install.sh)"
EOF

try_install_homebrew() {
  if should_install brew; then
    warn "We cannot continue without Homebrew."
    abort "Please run: '${BREW_INSTALL_CMD}'"
  fi
}

install_packages() {
  list git jq nvm | map try_brew_install
  execute brew upgrade
  execute brew cleanup --prune=all
  execute brew doctor
}

should_install_node() {
    local version=$1; shift
    if ! $(nvm version $version | grep -vq $version); then return 1; fi
}

ensure_docker_is_installed() {
    if should_install docker; then
        warn "We cannot continue without Docker."\
            "You can find the installer here: https://www.docker.com/get-started"
        abort "Please install docker"
    fi
}

# set_up_shell_nvm() {
#     if is_dry_run; then
#         deny 'Dry run: would write nvm configuration to shell configuration files.'
#     else
#       if ask 'Shall I modify your shell environment to support nvm?'; then
#           local nvm_bash_config="export NVM_DIR=\"\${HOME}/.nvm\"\n[ -s \"$(brew --prefix nvm)/nvm.sh\" ] && source \"$(brew --prefix nvm)/nvm.sh\"\n[ -s \"$(brew --prefix nvm)/etc/bash_completion.d/nvm\" ] && source \"$(brew --prefix nvm)/etc/bash_completion.d/nvm\"\n"
#           local check_pattern="source.*/nvm.sh"

#           append_if_missing "$check_pattern" "$nvm_bash_config" ~/.bash_profile
#           append_if_missing "$check_pattern" "$nvm_bash_config" ~/.zshrc

#           if command -v fish &> /dev/null; then
#               if [[ ! -e "${HOME}/.config/fish/functions/bass.fish" ]]; then
#                   warn "NVM integration for fish requires bass!"
#               fi
#               mkdir -p ~/.config/fish/functions
#               append_if_missing "export NVM_DIR" 'export NVM_DIR="$HOME/.nvm"' ~/.config/fish/config.fish
#               append_if_missing "function nvm" "function nvm --description 'Run NVM command in bash subshell.'\n\tbass source (brew --prefix nvm)/nvm.sh --no-use ';' nvm \$argv\nend" ~/.config/fish/functions/nvm.fish
#           fi
#       fi
#     fi
# }

# set_up_nvm_command() {
#     mention "Setting up nvm command"
#     export NVM_DIR="${HOME}/.nvm" && [ -s "$(brew --prefix nvm)/nvm.sh" ] && source "$(brew --prefix nvm)/nvm.sh"  # This loads nvm
#     claim "nvm command installed in current process"

#     mention "Using nvm, try installing node.js."
#     try_install 'should_install_node 10.15' 'node 10.15' 'nvm install 10.15'

#     say "Setting up nvm, so the user can use it."
#     set_up_shell_nvm
# }

say "Setting up"

try_install_homebrew
ensure_docker_is_installed

step_banner "First, install everything we can automatically"
install_packages