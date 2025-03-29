# AwesomeWM

<p align="center">
    <img src="assets/awm_preview.png">
</p>

<details>
<summary><b>Installation</b></summary>

#### Install dependencies:
1. necessary
```
xorg
xorg-xinit
awesome-git (aur)
luarocks
pulseaudio
pulseaudio-bluetooth
networkmanager
bluez
bluez-utils
picom
maim
```
2. optional (you also need terminal emulator, file manager etc.)
```
alacritty
nemo
leafpad
eom
mpv
nwg-look
```

#### Install lua modules

<div align="center">

| Module                                                            | Description                   |
| ----------------------------------------------------------------- | ----------------------------- |
| [luautf8](https://github.com/starwing/luautf8?tab=readme-ov-file) | Needed for text input widgets |

</div>

```
$ sudo luarocks install luautf8
```

#### Start & enable `network manager` & `bluez` services

#### Clone repo
```
$ git clone --depth 1 https://github.com/myagko/dotfiles.git
```

#### Copy contens of `dotfiles/home` to your home folder (i use `rsync` instead of copying every folder with `cp -r`)
```
$ rsync -avhu ~/dotfiles/home/ ~/
```

#### Download [JetBrainsMonoSlashed](https://github.com/sharpjs/JetBrainsMonoSlashed/releases) font and put it to `~/.fonts`

</details>

<details>
<summary><b>Customisation</b></summary>

#### Edit `~/.config/awesome/user.lua` as you need, you can set wm theme, choose default terminal, and set data for weather widget

#### Icons and themes
1. Install `themix-full-git` from aur
2. Export icons and theme from user presets

#### Cursors (`inkscape` required) ([source](https://github.com/charakterziffer/cursor-toolbox))
```
$ cd ~/dotfiles/extra/cursor_toolbox
$ ~/dotfiles/extra/cursor_toolbox/render-pngs.py ~/dotfiles/extra/cursor_toolbox/sharp_dark.svg
$ ~/dotfiles/extra/cursor_toolbox/make_dark.sh
$ cp -r sharp_cursors_dark ~/.icons
```

#### Firefox css
1. Search `about:config`.
2. `toolkit.legacyUserProfileCustomizations.stylesheets`, `layers.acceleration.force-enabled`, `gfx.webrender.all`, `svg.context-properties.content.enabled` change to `True`.
3. Copy `~/dotfiles/extra/mozilla/chrome` to `~/.mozilla/firefox/XXXXXXX.default-release/`.

#### Apply cursors, icons and gtk themes with `lxappearance` or `nwg-look`

</details>

<details>
<summary><b>Keybinds</b></summary>

<div align="center">

| Keybinding            | Description                              |
| --------------------- | ---------------------------------------- |
| `Mod+Shift+r`         | Restart awesomewm                        |
| `Mod+Tab`             | Switch to next client by index           |
| `Mod+Shift+Tab`       | Switch to previus client by index        |
| `Mod+Ctrl+Tab`        | Restore minimized client                 |
| `Mod+Shift+s`         | Swap with next client by index           |
| `Mod+Ctrl+s`          | Swap with previous client by index       |
| `Mod+Shift+a`         | Increase the number of master clients    |
| `Mod+Ctrl+a`          | Decrease the number of master clients    |
| `Mod+Shift+q`         | Increase the number of columns           |
| `Mod+Ctrl+q`          | Decrease the number of columns           |
| `Mod+Shift+e`         | Increase master width factor             |
| `Mod+Ctrl+e`          | Decrease master width factor             |
| `Mod+Ctrl+Shift+e`    | Reset master width factor                |
| `Mod+Space`           | Switch layout                            |
| `Mod+1...9`           | Only view tag                            |
| `Mod+Shift+1...9`     | Move focused client to tag               |
| `Mod+z`               | Close client                             |
| `Mod+x`               | (Un)Maximize client                      |
| `Mod+c`               | Minimize client                          |
| `Mod+v`               | Toggle client fullscreen                 |
| `Mod+b`               | Toggle client ontop                      |
| `Mod+n`               | Move client to center                    |
| `Mod+m`               | Toggle client menu                       |
| `Mod+Ctrl+Return`     | Move client to master                    |
| `Mod+d`               | Open app launcher                        |
| `Mod+q`               | Open powermenu                           |
| `Mod+Return`          | Open terminal                            |
| `Mod+Print`           | Take screenshot                          |
| `Mod+Shift+Print`     | Take screenshot area                     |

</div>

</details>