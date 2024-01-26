#!/bin/bash

RED=`tput setaf 1`
GREEN=`tput setaf 2`
YELLOW=`tput setaf 3`
BLUE=`tput setaf 4`
PURPLE=`tput setaf 5`
LIGHTBLUE=`tput setaf 6`
RESET=`tput sgr0`

echo -e "${RED}P${RED}${RESET}${YELLOW}a${YELLOW}${RESET}${GREEN}p${GREEN}${RESET}${BLUE}i${BLUE}${RESET}${PURPLE}r${PURPLE}${RESET}${RED}u${RED}${RESET}${LIGHTBLUE}s${LIGHTBLUE}${RESET} Folder Icon Creator - A shell script for create colorful folders!\n"

folders=('22x22' '24x24' '32x32' '48x48' '64x64')
colors=('4f4f4f' 'e4e4e4' 'ffffff' 'cccccc')
newColors=('292929' '86AB9D' 'BBBBBB' '86AB9D')

# nymph_cyan '252B2E' '89B7B0' 'BCC4C9' '89B7B0'
# satyr_cyan '292929' '86AB9D' 'BBBBBB' '86AB9D'

echo -n "Enter the name of the variant: "
read colorName

echo

if [ ! -d "New-Icons" ]; then
        mkdir "New-Icons";
        echo "The-New Icons folder was created!"
else
	echo "The-New Icons folder already exists!"
fi

echo

for folder in ${folders[*]}; do
    if [ ! -e "New-Icons"/$folder ]; then
        mkdir "New-Icons"/$folder;
        echo "The $folder folder was created!"
    else
    	echo "The $folder folder already exists!"
    fi
done

echo

echo "Creating icons..."
for folder in ${folders[*]}; do
    for icon in $(cat iconsNames.txt); do
        cat "Base-Icons"/$folder/$icon | sed -e "s/${colors[0]}/${newColors[0]}/" \
            -e "s/${colors[1]}/${newColors[1]}/" \
            -e "s/${colors[2]}/${newColors[2]}/" \
            -e "s/${colors[3]}/${newColors[3]}/" > "New-Icons"/$folder/` echo $icon | sed "s/white/$colorName/" `;
    done
done
echo "The icons were created!"
