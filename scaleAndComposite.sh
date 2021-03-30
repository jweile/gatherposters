#!/bin/bash

#first argument should be the poster number
posternum=$1
#second argument should be the poster image
rawimg=$2

maxsize=3000
# posternum=B3
# rawimg=2021-03-19_Church_MSC.png

mkdir -p processed

scaledimg=processed/${posternum}_full.png
previewimg=processed/${posternum}_preview.png
thumbimg=processed/${posternum}_thumb.png
icon=processed/${posternum}_icon.png
overlay=processed/overlay_${posternum}.png

echo "Checking file..."
if [[ $(file $rawimg) =~ "image data" ]]; then
  echo "Image recognized!"
else
  >&2 echo "Not an image!"
  exit 1
fi

#helper function to check if the image is oversized
checkSize() {
  resolution=$(identify -quiet $1|cut -f 3 -d" "|tr x "\n")
  for x in $resolution; do
    if [[ $x -ge $maxsize ]]; then
      return 1
    fi
  done
}

#convert to PNG and rescale to max allowed size if necessary
if ! checkSize $rawimg; then
	echo "Rescaling..."
	convert -quiet $rawimg -resize "${maxsize}x${maxsize}" $scaledimg
else
	#otherwise we just convert it to PNG format
  convert -quiet $rawimg $scaledimg
fi

#rescale to preview size
convert -quiet $scaledimg -resize 800x800 $previewimg
#rescale to thumbnail size
convert -quiet $scaledimg -resize 86x54 $thumbimg

echo "Building icon..."
#determine the final width of the thumbnail
thumbwidth=$(identify -quiet $thumbimg|cut -f 3 -d" "|sed -Ee 's/x.+//g')
#and calculate how far off-set it needs to be from the left edge of the board
#to be centered
offset=$(( 5+43-($thumbwidth/2) ))

#composite overlay over thumbnail and posterboard tile to generate icon
composite -quiet -geometry +${offset}+2 $thumbimg posterboard.png $icon
composite -quiet $overlay $icon $icon

#cleanup:  we don't need the thumbnail and overlay anymore
rm $thumbimg $overlay

echo "Done!"
