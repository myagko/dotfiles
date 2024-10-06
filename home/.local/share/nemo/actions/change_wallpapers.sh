#!/bin/bash
awesome-client "for s in screen do s.wallpaper:set_image('$1') end"
ESC_WP_PATH=$(printf %q "$1")
sed -i "s#M.wallpaper\s*=\s*.*#M.wallpaper = '$ESC_WP_PATH'#g" $HOME/.config/awesome/user.lua
