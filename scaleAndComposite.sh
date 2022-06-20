#!/bin/bash

#first argument should be the poster number
posternum=$1
#second argument should be the poster image
rawimg=$2

maxsize=3000
minsize=1000
# posternum=B3
# rawimg=2021-03-19_Church_MSC.png

mkdir -p processed

scaledimg=processed/${posternum}_full.png
tmpimg=processed/${posternum}_tmp.png
previewimg=processed/${posternum}_preview.png
thumbimg=processed/${posternum}_thumb.png
icon=processed/${posternum}_icon.png
overlay=processed/overlay_${posternum}.png

#Check if output already exists. if so we can skip
if [[ -f $scaledimg ]]; then
  echo "Already converted. Skipping..."
  exit 0
fi

echo "Checking file..."
if [[ $(file "$rawimg") =~ "image data" ]]; then
  echo "Image recognized!"
elif [[ $(file "$rawimg") =~ "PDF document" ]]; then
  echo "PDF recognized!"
else
  >&2 echo "Not an image!"
  exit 1
fi

#helper function to check if the image is oversized
checkSize() {
  # resolution=$(identify -quiet $1|cut -f 3 -d" "|tr x "\n")
  resolution=$(identify -quiet "$rawimg"|grep -oP '[0-9]+x[0-9]+'|head -1|tr x "\n")
  OUT=0
  for x in $resolution; do
    if [[ $x -ge $maxsize ]]; then
      ((OUT++))
    elif [[ $x -le $minsize ]]; then
      ((OUT--))
    fi
  done
  echo $OUT
}

#convert to PNG and rescale to max allowed size if necessary
if [[ $(file "$rawimg") =~ "PDF document" ]]; then
  sizeFlag=$(checkSize "$rawimg")
  if [[ $sizeFlag -gt 0 ]]; then
    convert -quiet "$rawimg" -resize "${maxsize}x${maxsize}" $scaledimg
  elif [[ $sizeFlag -lt 0 ]]; then
    gs -dSAFER -dBATCH -dNOPAUSE -sDEVICE=png16m -dGraphicsAlphaBits=4 -dTextAlphaBits=4 -r400 -sOutputFile=$tmpimg "$rawimg"
    convert -quiet "$tmpimg" -resize "${maxsize}x${maxsize}" -background white -flatten $scaledimg
    rm $tmpimg
  else
    convert -quiet "$rawimg" -background white -flatten $scaledimg
  fi
else #it's an image
  if [[ $sizeFlag -eq 0 ]]; then
    convert -quiet "$rawimg" -background white -flatten $scaledimg
  else
    convert -quiet "$rawimg" -resize "${maxsize}x${maxsize}" -background white -flatten $scaledimg
  fi
fi

# if ! checkSize "$rawimg"; then
#   echo "Converting and rescaling..."
#   if [[ $(file "$rawimg") =~ "PDF document" ]]; then
#     gs -dSAFER -dBATCH -dNOPAUSE -sDEVICE=png16m -dGraphicsAlphaBits=4 -dTextAlphaBits=4 -r400 -sOutputFile=$tmpimg "$rawimg"
#     convert -quiet "$tmpimg" -resize "${maxsize}x${maxsize}" $scaledimg
#     rm $tmpimg
#   else
#     convert -quiet "$rawimg" -resize "${maxsize}x${maxsize}" $scaledimg
#   fi
# else
#   #otherwise we just convert it to PNG format
#   echo "Converting to PNG.."
#   convert -quiet "$rawimg" $scaledimg
# fi

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
