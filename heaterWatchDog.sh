#!/bin/bash 
# 
# A script to watch an Android IPWebcam video feed and reset the 
# water heater when it shows an "E" on the display
#
 
WEBCAM="http://192.168.4.196:8080/video"
CROP="100x100+235+210"
THRESHOLD=6000

while sleep 1; do 
	# 1) Grab webcam frame as photo.jpg
	# 2) Crop it and threshold it to photo-c.jpg
	# 3) Search for relative match with target image e.jpg
	# 4) After fixed number of consecutive matches, reset the heater  

	#wget http://192.168.4.196:8080/photoaf.jpg -O photo.jpg
	ffmpeg -nostats -hide_banner -i $WEBCAM -frames:v 1 -y photo.jpg > /dev/null 2>&1 || continue 
	convert photo.jpg -crop $CROP -colorspace gray -threshold 80% -blur 1x2 photo-c.jpg || continue 

	# useful compare -metric values:  MAE MEPP MSE RMSE  PSNR
	ERR=`compare -metric MAE -subimage-search photo-c.jpg e.jpg diff.tiff 2>&1 | cut '-d ' -f 1`
	ERR=`printf %.0f $ERR`  # Convert from float to integer 
	if test $ERR -gt 0; then
		if test $ERR -lt $THRESHOLD -a $ERR -gt 0; then 
			ECOUNT=$(($ECOUNT + 1))
			if [[ $ECOUNT -gt 20 ]]; then 
				mosquitto_pub -h rp1.local -t '/circreset' -m ''
				cp photo-c.jpg err.`date +%s`.jpg # For debugging, save image that caused reset 
				ECOUNT=0
			fi
		else
			ECOUNT=0
		fi
    fi 
	
	POW=`mosquitto_sub -h rp1.local -t 'circpower' -C 1` # Note if power is currently on 
	echo `date +%s` $ERR $POW $ECOUNT | tee -a log.txt   # Log data 
	montage e.jpg photo-c.jpg diff.tiff m.jpg  # Make a thumbnail image for visual debugging 

done 

# Misc cookbook 
# Make a new target picture newe.jpg from the existing photo-c.jpg and the best-match spot of current e.jpg 
OFFSET=`compare -metric MAE -subimage-search photo-c.jpg e.jpg diff.tiff 2>&1  | cut '-d ' -f4  | tr ',' '+'`
convert photo-c.jpg  -crop 17x22+$OFFSET newe.jpg && feh newe.jpg 






