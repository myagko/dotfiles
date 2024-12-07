#!/bin/bash

awesome-client "for s in screen do s.wallpaper:set_image(\"$1\") end"
sed -i "s#M.wallpaper\s*=\s*.*#M.wallpaper = \"$(printf %q "$1")\"#g" $HOME/.config/awesome/user.lua
