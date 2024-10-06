#!/bin/sh

xrdb -merge ~/.Xresources
#xrandr --output DisplayPort-0 --primary --mode 1920x1080 --rate 165.00 --rotate normal &
#setxkbmap -model pc105 -layout us,ru -option grp:alt_shift_toggle &
#xinput set-prop 'Glorious Model O' 'libinput Accel Speed' -1 &
#/usr/lib/polkit-gnome/polkit-gnome-authentication-agent-1 &
exec awesome


