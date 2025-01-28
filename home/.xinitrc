#!/bin/sh

xrdb -merge ~/.Xresources
# xrandr --output DisplayPort-0 --primary --mode 1920x1080 --rate 165.00 --rotate normal &
/usr/lib/polkit-gnome/polkit-gnome-authentication-agent-1 &
picom &
exec awesome
