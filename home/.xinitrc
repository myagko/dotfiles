#!/bin/sh

xrdb -merge ~/.Xresources

/usr/lib/polkit-gnome/polkit-gnome-authentication-agent-1 &
xrandr --output DisplayPort-0 --mode 1920x1080 --rate 165.00 &

LANG=C exec awesome


