#!/bin/sh
sed -i \
         -e 's/#1F1F1F/rgb(0%,0%,0%)/g' \
         -e 's/#BBBBBB/rgb(100%,100%,100%)/g' \
    -e 's/#1F1F1F/rgb(50%,0%,0%)/g' \
     -e 's/#86AB9D/rgb(0%,50%,0%)/g' \
     -e 's/#292929/rgb(50%,0%,50%)/g' \
     -e 's/#BBBBBB/rgb(0%,0%,50%)/g' \
	"$@"
