#
# ~/.bashrc
#

# If not running interactively, don't do anything
[[ $- != *i* ]] && return

PS1='\[\e[96m\][\[\e[39m\]\u\[\e[96m\]@\[\e[39m\]\H\[\e[96m\]:\[\e[95m\]\w\[\e[96m\]]$\[\e[39m\] '

[ -z "$DISPLAY" -a x$XDG_VTNR = x1 ] && exec startx

alias ls='ls --color=auto'