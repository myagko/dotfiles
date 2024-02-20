<div align="center">
    <img src="./src/12.png"> 
</div>

## Guide

<details>
<summary><b>Installation</b></summary>

- Install dependencies
```
$ sudo pacman -S xorg-server xorg-xinit xorg-xrandr xorg-xcursorgen \
pulseaudio networkmanager bluez bluez-utils rsync \
alacritty picom maim imagemagick lxappearance firefox ttf-iosevka-nerd
```

- Install `awesome-git` package from aur (pikaur for example)
```
$ pikaur -S awesome-git
```

- Start & enable `network manager` & `bluez` services

- Setup home dir
```
$ git clone --depth 1 https://github.com/myagko/dotfiles.git
$ rsync -avhu ~/dotfiles/home/ ~/
```

<h1></h1>
</details>

<details>
<summary><b>Post-install setup</b></summary>

- Change `~/.config/awesome/user.lua`

- Cursors [guide](https://github.com/charakterziffer/cursor-toolbox)
```
$ cd ~/dotfiles/extra/cursor_toolbox
$ ~/dotfiles/extra/cursor_toolbox/render-pngs.py ~/dotfiles/extra/cursor_toolbox/Sharp_custom.svg
$ ~/dotfiles/extra/cursor_toolbox/make.sh
```

- Papirus icons [guide](https://github.com/Adapta-Projects/Papirus-Folder-Icon-Creator)
```
$ cd ~/dotfiles/extra/papirus_folder_icon_creator
$ ~/dotfiles/extra/papirus_folder_icon_creator/change_folders_colors.sh
$ ~/dotfiles/extra/papirus_folder_icon_creator/add_folders.sh
$ ~/tihon/dotfiles/extra/papirus_folder_icon_creator/apply_folders.sh -C satyr_cyan -t Papirus-Dark
```

- Firefox css
1. Search `about:config`.
2. `toolkit.legacyUserProfileCustomizations.stylesheets`, `layers.acceleration.force-enabled`, `gfx.webrender.all`, `svg.context-properties.content.enabled` change to `True`.
3. Copy `~/dotfiles/extra/mozilla/chrome` to `~/.mozilla/firefox/XXXXXXX.default-release/`.

- Firefox startpage
1. Edit `/usr/lib/firefox/autoconfig.cfg`
```
var {classes:Cc,interfaces:Ci,utils:Cu} = Components;
try {
  Cu.import("resource:///modules/AboutNewTab.jsm");
  var newTabURL = "file:///home/username/yourfile.html";t
  AboutNewTab.newTabURL = newTabURL;
} catch(e){Cu.reportError(e);}
```
2. Edit `/usr/lib/firefox/defaults/pref/autoconfig.js`
```
pref("general.config.filename", "autoconfig.cfg");
pref("general.config.obscure_value", 0);
pref("general.config.sandbox_enabled", false);
```
3. Set homepage at firefox settings

<h1></h1>
</details>

<details>
<summary><b>Keybindings</b></summary>

| Keybinding            | Description                              |
| --------------------- | ---------------------------------------- |
| `Mod+Shift+r`         | Restart awesomewm                        |
| `Mod+b`               | move client to center                    |
| `Mod+v`               | toggle client fullscreen                 |
| `Mod+z`               | close client                             |
| `Mod+x`               | minimize client                          |
| `Mod+c`               | (un)maximize client                      |
| `Mod+Tab`             | switch client                            |
| `Mod+Shift+s`         | swap with next client by index           |
| `Mod+Ctrl+s`          | swap with previous client by index       |
| `Mod+Shift+a`         | increase the number of master clients    |
| `Mod+Ctrl+a`          | decrease the number of master clients    |
| `Mod+Shift+q`         | increase the number of columns           |
| `Mod+Ctrl+q`          | decrease the number of columns           |
| `Mod+Shift+e`         | increase master width factor             |
| `Mod+Ctrl+e`          | decrease master width factor             |
| `Mod+Ctrl+Shift+e`    | reset master width factor                |
| `Mod+Space`           | switch layout                            |
| `Mod+1...9`           | only view tag                            |
| `Mod+Shift+1...9`     | move focused client to tag               |
| `Mod+d`               | open app launcher                        |
| `Mod+q`               | open powermenu                           |
| `Mod+f`               | open control center widget               |
| `Mod+w`               | open terminal                            |
| `Print`               | take screenshot                          |
| `Shift+Print`         | take screenshot area                     |

<h1></h1>
</details>