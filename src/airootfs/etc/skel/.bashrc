#
# ~/.bashrc
#

# If not running interactively, don't do anything
[[ $- != *i* ]] && return

alias ls='ls --color=auto'
PS1='[\u@\h \W]\$ '

alias version="sed -n 1p /etc/os-release-gsos && sed -n 12p /etc/os-release-gsos && sed -n 13p /etc/os-release-gsos"
