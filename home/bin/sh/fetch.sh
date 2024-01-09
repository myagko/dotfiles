#!/bin/sh

user=$(whoami)
host=$(hostnamectl | grep -i hostname | awk '{print $3}')

os=$(. /etc/os-release && echo $ID)

read -r _ _ version _ < /proc/version
kernel=${version%%-*}

if command -v pacman >/dev/null; then
	packages=$(pacman -Q | wc -l)
elif command -v dpkg >/dev/null; then
	packages="$(dpkg-query -f '.\n' -W | wc -l)"
elif command -v rpm >/dev/null; then
	packages=$(rpm -qa | wc -l)
elif command -v xbps-query >/dev/null; then
	packages=$(xbps-query -l | wc -l)
elif command -v emerge >/dev/null; then
	packages=$(ls -d /var/db/pkg/*/* | wc -l)
elif command -v apk >/dev/null; then
	packages=$(apk info | wc -l)
fi

shell=${SHELL##*/}

id=$(xprop -root -notype _NET_SUPPORTING_WM_CHECK)
id=${id##* }
wm=$(xprop -id "$id" -notype -len 100 -f _NET_WM_NAME 8t)
wm=${wm##*WM_NAME = \"}
wm=${wm%%\"*}

printf "
\e[36m    ${user}\e[39m@\e[36m${host}
\e[36m    os\e[39m      -  ${os}
\e[36m    kernel\e[39m  -  ${kernel}
\e[36m    pkgs\e[39m    -  ${packages}
\e[36m    shell\e[39m   -  ${shell}
\e[36m    wm\e[39m      -  ${wm}
\e[36m    \e[90m▁▁\e[31m▁▁\e[32m▁▁\e[33m▁▁\e[34m▁▁\e[35m▁▁\e[36m▁▁\e[39m▁▁

" | tr '[:upper:]' '[:lower:]'