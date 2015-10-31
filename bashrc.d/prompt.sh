# Set up the bash prompt nicely
# -----------------------------

# Build up PS1
export VIRTUAL_ENV_DISABLE_PROMPT=true

sep="╱"
list=$( ppids  "$sep" "tmux" "urxvt" "init" "sh" "exo-helper-1" "x-terminal-emulator" )
if [ -n "$LC_SSH_PPLIST" ] && [[ "${list}" = sshd"${sep}"* ]] ; then
	list="${LC_SSH_PPLIST}${sep}${list##*sshd${sep}}"
fi

list=$( sed "s#$( basename "$SHELL" )#"'$'"#g" <<<"$list" )

if [ "$list" != '$' ] ; then
	export _PARENT_PROCESS_LIST="$list"
else
	export _PARENT_PROCESS_LIST=""
fi
export LC_SSH_PPLIST="${list}${sep}»$( hostname )"

VCPROMPT="$HOME/.bashrc.d/vcprompt"
GIT_PROMPT_ONLY_IN_REPO=1

# Set PS1. Levels are:
# * 0, low, minimal: Minimal PS1. Useful for slow systems, or systems with
#   basic shells
# * 1, medium, normal: Prompt showing coloured information, including
#   virtualenv status
# * 2, high, full: Prompt showing coloured information, including virtualenv
#   and version control status
function prompt-level() {
	user='\[\e[38;5;40m\]\u\[\e[0m\]'
	host='@\[\e[38;5;13m\]\h\[\e[0m\]'
	path=':\[\e[38;5;202m\]\w\[\e[0m\]'
	venv='$( if [[ x"$VIRTUAL_ENV" != x ]] ; then dir="${VIRTUAL_ENV%%/venv}"; dir="${dir##*/}" ; echo "⚒\[\e[38;5;51m\]$dir\[\e[0m\]" ; fi )'
	running='$( ! [ -z "$_PARENT_PROCESS_LIST" ] && echo "↳\[\e[38;5;93m\]$_PARENT_PROCESS_LIST\[\e[0m\]" )'
	level=$1
	case $level in
	0|off|none)
		level=0
		export PS1='\$ '
		;;
	1|low|minimal)
		level=1
		export PS1='[\u@\h:\W] \$ '
		;;
	2|medium|normal)
		level=2
		export PS1='\n'"$user$host$path"'\n\$ '
		;;
	3|high|full)
		level=3
		export PS1='\n['"$user$host$venv$running$path"']\n\$ '
		;;
	*)
		echo "Unknown prompt-level: $1"
		return 1
	esac

	export PROMPT_LEVEL=$level
}
source ~/.git-prompt/gitprompt.sh

function ++prompt () {
	level=$(( $PROMPT_LEVEL + 1))
	prompt-level $level
}

function --prompt () {
	level=$(( $PROMPT_LEVEL - 1))
	prompt-level $level
}

prompt-level "${PROMPT_LEVEL:-2}"
