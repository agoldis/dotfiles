#!/bin/bash

# No bell, fast keyboard repeat rate
xset r rate 160
xset b off

# Xresources
test -e "$HOME/.Xresources.local" && xrdb -merge /home/tim/.Xresources.local

# Source local stuff (xrandr screens, etc)
test -x ~/.xsession.local && ~/.xsession.local

# Window manager
exec \
	ck-launch-session \
	gpg-agent --enable-ssh-support --daemon \
	i3
