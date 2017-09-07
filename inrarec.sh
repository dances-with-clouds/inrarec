#!/bin/bash
#
#####################################################################
#
# inrarec - internet radio recorder
#
# A small wrapper for streamripper.
# 
# Author: Wolfgang Klein (klein.wolfg@web.de)
#
# Version: 2017-09-06
# 
# 
# This script uses streamripper to record internet streams transmitted by
# internet radio stations, and then it uses sox to split those streams 
# into separate songs and to add a little fading. It can also burn the 
# songs to a CDRW or copy them onto a USB drive.
#
#
# It can also be started by udev to burn or copy a previously made 
# recording without further interacting: just plug in a USB drive 
# or insert a CDRW, and the process starts.
# 
# To use this feature, you have to give certain volume names to the USB
# drive and the CDRW before using them. See below for instructions. 
#
#
# Important note:
# 
# As of now, inrarec can only download and handle streams in mp3 format!
#
# Make sure you use the mp3 stream when you want to use this script to
# record an internet radio station!
#
# Right now I can't tell if I will add support for other formats as well, 
# because a mp3 stream should be provided by almost any radio station.
#
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#
# Wait a minute... this sounds like something that streamripper and 
# fadecut can do!
#
# 
# That is correct. So why did I do it?
#
# Streamripper and fadecut are great programms, no question about it! 
#
# But soon after I started to use them, I realized they did not quite 
# fit my personal needs. So I started to write a small script that would
# do the every day work for me, and it started with just 5 lines of code 
# for cron, that would download a few hours of songs from a radio station 
# and burn them onto a CD, so I could enjoy the music the next day while
# driving my truck, without getting bored and annoyed by being forced
# to listen to the "heavy rotation" loop that most FM radio station 
# transmit these days and that simply drive my mad. I hate hearing the
# same set of songs in the order three times a day!
#
# While enhancing my script, it grew on me, and I started to include more 
# and more features, and this is the result. 
# 
# And most probably, this will not be the final result yet. :)
#
# But beware: 
# 
# As I said, I wrote this script to fit my needs. Use it at your own risk!
#
# Don't hold me responsible when it makes your PC go haywire, your milk
# turns sour after starting it, or your cat brings in some nasty stuff 
# from the garden!
#
# Nonetheless, I hope that others may find it useful as well. I've used it 
# for quite some time now, and it works pretty flawlessly - at least at my
# machine!
#
# If you do find any bug or if you have suggestions for making it better,
# don't hesitate to contact me.
#
#####################################################################
#
# inrarec is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# inrarec is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details:
# http://www.gnu.org/licenses/
#
#####################################################################
#
#
# Configuration / setting some variables:
#

#
# Where to send e-mails when a job is finished?
# If empty, no e-mail will be send!
#
EMAIL=""

#
#
# Which file contains names and titles of unwanted artists and songs?
DONTLIKE="$HOME/.inrarec/dontlike"

#
# Using a file for unliked songs enables this script to exclude certain 
# artists, regardless which song they (try to) sing, and also to exclude 
# certain songs, regardless who performs it. 
#
# The contents of this file can look like this:
#
# ------------------
# song title - artist
# * - artist
# song title - * 
# ------------------
# 
# The syntax is quite obvious:
# - the first example excludes a specific song by a specific artist,
# - the second example excludes any song by a specific artist,
# - the third example excludes a specific by any artist.
# 
# So don't include a line saying "* - *". :)
#

# 
# profile dir
PROFILEDIR=$HOME/.inrarec/profiles

# 
# The profiles that this script uses are identical to the ones that 
# fadecut uses. If you have fadecut profiles, you can even set 
#
# PROFILEDIR=$HOME/.fadecut/profiles 
#
# A typical profile looks like this
# ---------------------- cut here ---------------------
STREAM_URL="http://www.radioparadise.com/m3u/mp3-128.m3u"
GENRE="Alternative"
COMMENT="Radio Paradise"
# all values in seconds:
FADE_IN=1
FADE_OUT=5
TRIM_BEGIN=1
TRIM_END=1
ENCODING=mp3 
# ---------------------- cut here ---------------------

#
# Default profile. 
# May be given as command line argument "-p <profilename>" as well.
PROFILE="radioparadise"

#
# streamripper:
# Options for streamripper, see "man streamripper":
STREAMRIPPER_OPTS="-o always -T -k 1 -s --with-id3v1 --codeset-filesys=UTF-8 --codeset-id3=UTF-8 --codeset-metadata=UTF-8"

#
# Default limit for downloading, can be set via command line option.
# Possible options for limit:
#
# "-s 60"		60 seconds
# "-m 30" 		30 minutes
# "-h 12"		12 hours
# "-d 2" 		2 days
# "-M 500 		500 MB
# "-G 2"		2 GB
#
SRLIMIT="-M 690"

#
# lame
#
LAME=

#
# Base dir to be used for recording, can be set via "-d <director>":
#
RECBASEDIR=/mnt/aufnahmen
#RECBASEDIR=$HOME/tmp/aufnahmen

#
# Which file contains recordings that already have been burned onto a CD?
# This file simply prevents burning the same recording again and again,
# when a "headless" machine is used. 
#(Doesn't really need to be changed!)
BURNED="$RCDIR/burned"

#
# Maximum number of recordings? (To prevent flooding the hard disk!)
# Value of zero means no limit!
#
# MAXRECORDINGS=0
MAXRECORDINGS=5


#
# Which binaries to use for burning a CD?
CDRECORD=/opt/schily/bin/cdrecord
MKISOFS=/opt/schily/bin/mkisofs
#
# If you want to use the system's default binaries, just uncomment the 
# following two lines:
#CDRECORD=$(which cdrecord)
#MKISOFS=$(which mkisofs)


# The CD-RW device:
DEVICE=/dev/sr0

# Copying to USB drive:
#
# The following settings are important, if you want to use udev to burn
# a CD, as soon as you insert a blank disk, or if you want to copy recorded
# music to a USB drive. See below.
#
# Mounting point for the USB drive, that the recording is to be copied to.
# If empty, nothing will be copied!
#
# USBMUSIC=""
USBMUSIC=/mnt/music

#
# Important: to enable this script to automatically mount the USB disk without
# root permissions, you need to put a line like this into /etc/fstab:
#
# LABEL=MYMUSIC            /mnt/music             auto    user,noauto,defaults    0 0
# 
# The important option is the option "user", see "man mount"!
# Don't forget to hange the drive's label! 


# CD:
#
# Value (label) to give to a burned CDRW. (See below):
VALUE="One for the road..."


# udev stuff: 
#
#To automate burning and/or copying to USB drive, you have to use udev!
#
# First, you need to create /etc/udev/rules/99-inrarec.rules like this:
#
# SUBSYSTEM=="block", KERNEL=="sr0", ACTION=="change", ENV{ID_CDROM_MEDIA_STATE}=="complete", ENV{ID_FS_LABEL}=="One_for_the_road", RUN+="/bin/su -l <yourusername> -c '/path/to/inrarec.sh -udev cd &'"
#
# SUBSYSTEMS=="usb", KERNEL=="sd[b-z]*", ACTION=="add", ENV{ID_FS_LABEL}=="MYMUSIC", RUN+="/bin/su -l <yourusername> -c '/path/to/inrarec.sh -udev usb &'" 
#
# Use the command "/sbin/udevadm info --query=all --path=/sys/block/sr0" 
# to get appropriate arguments.
#
# Then you have to label the USB drive and/or the CDRW as shown above.
# 
# Call "sudo udevadm control --reload" to activate this rule.
# 
# Then, as soon as you insert the appropriate USB drive or CDRW, 
# the recording will be automatically be copied/burned. 
# 
# This is espacially handy on a headless machine, and that's the reason 
# why I included this feature in the first place! :)
# 
#
#####################################################################
####
#### Let's go!
#### 
#### Nothing needs to be changed below this line!!! (I hope...)
####
#####################################################################

#
# To be able to change IFS temporarily, whenever handling file names
# that could contain blanks.
#
# Beware: streamripper doesn't like a modified IFS, so it can't
# be changed globally for the whole script!
# 

OLDIFS="$IFS"
TMPIFS='
'

help()
{
cat<<EOF

Usage:

$0 [finalaction] [-k] [-p profile] [limit] [-d targetdir]

<finalaction> can be one of
-cd			burn to cd after ripping and trimming
-rsync <path>		sync to <path> after ripping and trimming
			  e.g.: -rsync /mnt/usbmemory/

-k:			keep the original downloads from streamripper

-p profile:		which profile to use

-d targetdir:		where to store the recording(s).

limit can be one of:

-s 60			60 seconds
-m 30 			30 minutes
-h 12			12 hours
-d 2 			2 days
-M 500 			500 MB
-G 2			2 GB

Default limit: 		700MB
Default station:	Radio Paradise

Alternate usage (use with caution!):

$0 -copy2usb | -burnlatest

-copy2usb		copy *all* recordings to a predefined USB drive.
-burnlatest		burn the *latest* recording to a CD(RW).


EOF
exit
}

do_rsync()
{
  if [ ! -x $(which rsync) ]
  then
    echo
    echo Error: rsync not found or not executable! 
    echo 
    echo Downloading songs is still possible, but if you want to copy them
    echo to some other place \(e.g. a USB drive\), rsync is required!
    echo
  else
	dest="$1"

        for vz in "$RECBASEDIR"/[a-zA-Z0-9]*;
        do
                vz=${vz##*/}
		# do not sync while working dir exists!
                if [ ! -d "$RECBASEDIR"/".${vz}" ]
                then
                        nice -n 19 rsync -a --exclude ".*/" --exclude ".*" "$RECBASEDIR"/"$vz" "$dest/"
                fi
        done
	
	sync
  fi
}


copy2usb()
{	

	IFS=$TMPIFS
	dest="$1"
	mount "$dest"

	if ! mountpoint -q "$dest";
	then
        	date | mail -s 'Target can not be mounted!' $EMAIL
	        exit
	fi

	free=$(df "$dest" --output=avail | tail -1)
	needed=$(du -s "$src" | cut -f1)

	## turn contents into numerical values:
	free=$(( $free + 1 ))
	needed=$(( $needed + 1 ))

	
	if [ $needed -gt $free ];
	then
	       echo Not enough space left on device! | mail -s "No music today" $EMAIL
	       umount $dest
	       exit
	fi

	do_rsync "$dest"

	umount "$dest"

	IFS=$OLDIFS
}

cdrw()
{
  if [ ! -x $CDRECORD ]
  then

    echo
    echo Error: cdrecord found or not executable! 
    echo 
    echo Downloading songs is still possible, but if you want to burn them
    echo to a CDRW, cdrecord is required! 
    echo

  elif [ ! -x $MKISOFS ]
  then	

    echo
    echo Error: mkisofs found or not executable! 
    echo 
    echo Downloading songs is still possible, but if you want to burn them
    echo to a CDRW, mkisofs is required! 
 
  else

	IFS=$TMPIFS

	src="$1"
	value="$2"

	if [ "xxx$src" = "xxx" ]
	then
		echo I\'ll stay cool because there\'s nothing to burn...
		return
	fi

	if $CDRECORD -minfo | grep -E 'Mounted media type: +CD-RW';
	then
		graft=${src##*/}
	
		#echo "$graft"
	       	#echo "$src" 
		#echo "$value"
        	#exit
 
		ts=$($MKISOFS -quiet -print-size "$src"/)s
		$CDRECORD dev=$DEVICE -force blank=fast -gracetime=0
		$MKISOFS -V "$value" -J -R -graft-points "$graft"="$src" \
		| $CDRECORD dev=$DEVICE -sao driveropts=burnfree \
			-gracetime=0 -data -eject fs=16m -tsize=$ts -
		
		[ $? -eq 0 ] && echo "$DATE: $src" >> $BURNED

	else
		echo No CD-RW available!
	fi
	IFS=$OLDIFS
  fi
}

findlatest()
{	
	IFS=$TMPIFS
	touch "$BURNED"
	found=""
	ALLRECORDINGS=$(find $RECBASEDIR -name '[!.]* - 20[0-9][0-9]-[0-9][0-9]-[0-9][0-9]' -type d -print \
	 		| sed -e 's/^.* \([[:graph:]]\{1,\}\)$/\1 &/' \
			| sort \
	      		| sed -e 's/^\([[:graph:]]\{1,\}\) //')
	      
	for recording in $ALLRECORDINGS;
	do
		  workingdir="$RECBASEDIR/.${recording##*/}"
		  tocheck=$(grep "${recording##*/}" "$BURNED")
		  if [ "xxx$tocheck" != "xxx" ]
		  then
		    # has been burned before
		    continue
		  elif [ -e "$recording" -a ! -e "$workingdir" ]
		  then
		     found="$recording"
		     break
		  fi
	done
	echo "$found"
	IFS=$OLDIFS
}

fadeout()
{
  
  FILE="$1"
  DEST="$2"
 
  echo "Trimming ${FILE}..."
 
  TIMESTAMP="$(date -R -r "$FILE")"
  BASENAME="${FILE##*/}"
  
  #echo
  # echo $BASENAME
  #echo $TMPFILE

  sox -V1 "$FILE" -t wav "$TMPDIR"/"$BASENAME".wav silence 1 0.50 0.1% 1 0.5 0.1% : newfile : restart
 
  #choose biggest file of sox output as we think this will be the wanted main part
  Ftmp=$(ls -1S "$TMPDIR"/"$BASENAME"* | head -1)
  #echo "Ftmp: $Ftmp"
  
  LENGTH=$(sox --i -D "$Ftmp")
  LENGTH=${LENGTH%%.*}
  TRIMLENGTH=$((LENGTH - TRIM_BEGIN - TRIM_END))
  FADE_OUT_START=$((TRIMLENGTH - FADE_OUT))

  sox -V1 "$Ftmp" -t wav - trim $TRIM_BEGIN $TRIMLENGTH \
	  silence -l 1 0.5 0.1% -1 0.5 0.1% \
	  fade t $FADE_IN $FADE_OUT_START $FADE_OUT \
      | lame --quiet --add-id3v2 --ta "$ARTIST" --tt "$TITLE" \
	--tg "$GENRE" --tc "$COMMENT" - "$DEST"

  touch -d "$TIMESTAMP" "$DEST"

  rm -f "$Ftmp"* 

}

#####################################################################

if [ ! -x $(which streamripper) ]
then
  echo
  echo Error: streamripper not found or not executable! 
  echo 
  exit
fi

if [ ! -x $(which lame)  ]
then
  echo
  echo Error: lame not found or not executable! 
  echo 
  exit
fi

if [ ! -x $(which sox)  ]
then
  echo
  echo Error: sox not found or not executable! 
  echo 
  exit
fi

if [ ! -x $(which id3v2) ]
then
  echo
  echo Error: id3v2 not found or not executable! 
  echo 
  exit
fi


TMPDIR=/tmp

# Date format, used as part of directory naming - DO NOT CHANGE!!!
DATE=$(date "+%F")
START=$(date "+%F %X")

FINALACTION=""
TIMEOUT=""

while [ $# -gt 0 ];
do
   case "$1" in
		"-k")
			KEEPORIG="true"
			shift
			;;
		"-d")
			RECBASEDIR="$2"
			mkdir -p "$RECBASEDIR"
			shift
			shift
			;;
            	"-cd")
                	FINALACTION="cdrw"
                    	shift
                    	;;
            	"-rsync")
                    	FINALACTION="copy2usb \"$USBMUSIC\""
			shift
                    	shift
                    	;;
		"-p")
			PROFILE=$2
			shift
			shift
			;;
		"-M")
			SRLIMIT="-M $2"
			shift
			shift
			;;
		"-G")
			SRLIMIT="-M $(( $2 * 1000))"
			shift
			shift
			;;
		"-s")
			SRLIMIT="-l $2"
			shift
			shift
			;;
		"-m")
			SRLIMIT="-l $(( $2 * 60))"
			shift
			shift
			;;
		"-h")
			SRLIMIT="-l $(( $2 * 60 * 60))"
			shift
			shift
			;;
		"-d")
			SRLIMIT="-l $(( $2 * 60 * 60 * 24))"
			shift
			shift
			;;
		"-udev")
			# script has been started by udev
			#
			# The reason for using the "at" command here is udev
			# doesn't run programms that last too long. Burning
			# a CD or using rsync definately is too long!
			if [ "$2" = "cd" ]
			then
			     echo "$0 -burnlatest" | /usr/bin/at now + 1 minute	
			     exit			     
			elif [ "$2" = "usb" ]
			then
			     echo "$0 -copy2usb" | /usr/bin/at now + 1 minute	
			     exit			     
			else
			    echo Unknown pair of arguments: "$1" "$2"
			    exit
			fi
			;;
		 "-burnlatest")
			 cdrw "$(findlatest)" "$VALUE"
			 exit
			 ;;
		"-copy2usb")
			copy2usb "$USBMUSIC"
			exit
			;;
		  "-f")
			  # don't check for another running instance
			  USETHEFORCE="true"
			  shift
			  ;;
		*)
                    help
                    exit
                    ;;
  esac
done



if [ ! -e $PROFILEDIR/$PROFILE ]
then
  echo
  echo Profile $PROFILE does not exist!
  echo
  exit
fi

if [ ! -d "$RECBASEDIR" ]
then
  echo $RECBASEDIR does not exist and can not be created!
  echo
  echo Create it manually or set the variable RECBASEDIR 
  echo appropriatly in $RCFILE!
  echo
  exit
fi

. $PROFILEDIR/$PROFILE

WORKINGDIR="$RECBASEDIR/.${COMMENT} - ${DATE}"
TARGET="$RECBASEDIR/${COMMENT} - ${DATE}"

#echo $WORKINGDIR
#echo $TARGET
#exit 

RECORDINGS=$(find "$RECBASEDIR" -type d -name "[!.]* - 20[0-9][0-9]-[0-9][0-9]-[0-9][0-9]" | wc -l)

if [ "xxx$USETHEFORCE" = "xxx" ]
then
  if [ "xxx$MAXRECORDINGS" != "xxx" ]
  then
      RECORDINGS=$(( $RECORDINGS + 0 ))
      if [ $MAXRECORDINGS -ge 0 -a $RECORDINGS -ge $MAXRECORDINGS ]
      then
	  echo Too many recordings found: 
	  echo check $RECBASEDIR and delete unnecessary recordings!
	  echo 
	  echo Maybe you should use the force, Luke...
	  echo
	  exit
      fi
  fi
fi

if [ "xxx$USETHEFORCE" = "xxx" ]
then
  if [ -d "$WORKINGDIR" ]
  then
	  echo Directory \"$WORKINGDIR\" already exists. Is there a recording running?
	  echo 
	  echo Maybe you should use the force, Luke...
	  echo
	  exit
  fi
fi

if [ "xxx$FINALACTION" = "xxx" ];
then
        echo After ripping and trimming, no further action will be taken!
	# FINALACTION="echo Done!"
fi


echo $START: Starting recording in \"${WORKINGDIR}\"...
renice -n 19 $$

mkdir -p "$TARGET"
mkdir -p "$WORKINGDIR"/{new,error,incomplete,orig}

streamripper $STREAM_URL $STREAMRIPPER_OPTS $SRLIMIT -d "$WORKINGDIR"

IFS=$TMPIFS

number=$(ls -1 "$WORKINGDIR"/*.mp3 | wc -l)
digits=${#number}

ALLSONGS=""
if [ -d "$WORKINGDIR" ];
then
  # sort by reverse date (oldest file first):
  ALLSONGS=$(ls -1rt "$WORKINGDIR/"*.mp3)
  if [ "xxx$ALLSONGS" != "xxx" ]
  then	
    i=1
    for song in $ALLSONGS
    do
      
      ARTIST=$(id3v2 -l "$song" | sed -e '/TPE1/!d' -e 's/^.*: //g')
      TITLE=$(id3v2 -l "$song" | sed -e '/TIT2/!d' -e 's/^.*: //g')

      number=$(printf "%0${digits}d\n" $i)
      newname="$number - ${song##*/}"
      DEST="$TARGET"/"${newname}"

      #echo "Datei: $song" 
      #echo "Ziel: $DEST" 
      #echo "Zeitstempel: $TIMESTAMP"

      dontlikethissong=$(grep -i "\* - $TITLE" $DONTLIKE)
      dontlikethisartist=$(grep -i "$ARTIST - \*" $DONTLIKE)
      dontlikethissongbythisartist=$(grep -i "$ARTIST - $TITLE" $DONTLIKE)
	
      if [ "xxx${dontlikethissong}" != "xxx" ] ; then
	echo "\"$song\": I don't like this song at all. It's listed in \"$DONTLIKE\" -> deleting..."
	rm -f "$song"
	continue
      fi
	
      if  [ "xxx${dontlikethisartist}" != "xxx" ] ; then
	echo "\"$song\": I don't like this artist at all. He/she is listed in \"$DONTLIKE\" -> deleting..."
	rm -f "$song"
	continue
      fi

      if  [ "xxx${dontlikethissongbythisartist}" != "xxx" ] ; then
	echo "\"$song\": I don't like this song by this artist. It's listed in \"$DONTLIKE\" -> deleting..."
	rm -f "$song"
	continue
      fi
     
      fadeout "$song" "$DEST" "$TIMESTAMP"
      i=$(( i + 1))

    done

  fi

fi

if [ "xxx$KEEPORIG" = "xxxtrue" ]
then
  mkdir -p "$TARGET"/orig
  echo You will find the original downloads in "$TARGET"/orig!
  mv "$WORKINGDIR"/*.mp3 "$TARGET"/orig/
fi

#rm -rf "$WORKINGDIR"

########################################################################

IFS=$OLDIFS

$FINALACTION
FINISH=$(date "+%F %X")
SECONDS=$(($(date "+%s" --date="-d $FINISH") - $(date "+%s" --date="-d $START")))
TDIFF=$(($(date "+%s" --date="-d $FINISH") - $(date "+%s" --date="-d $START")))


if [ "xxx$EMAILxxx" != "xxx" ]
then
    if [ ! -x $(which mail) ]
    then
      echo
      echo Error: mail not found or not executable! 
      echo 
      echo Downloading songs is still possible, but if you want to be notified
      echo by e-mail afterwards, a functioning mail system is required!
      echo
    else
      echo ... on \"$TARGET\" | mail -s "Thank you for the music..." $EMAIL
    fi
else
  echo $FINISH: Done! The job took me $(printf '%02dh:%02dm:%02ds\n' $(($TDIFF/3600)) $(($TDIFF%3600/60)) $(($TDIFF%60))). 
  echo Check for new music in \"$TARGET\" and enjoy!
fi

