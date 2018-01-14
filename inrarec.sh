#!/bin/bash
#
#####################################################################
#
# inrarec - internet radio recorder
# 
# A small wrapper for streamripper.
# 
# Version/Date: 2018-01-14
#
# This script uses streamripper to record internet streams transmitted by
# internet radio stations, and then it uses ffmpeg to add a little fading 
# at the beginning and the end, to get rid of any voice over and adds.
# It can also burn the songs to a CDRW or copy them onto a USB drive.
# 
# It can also be started by udev to burn or copy a previously made 
# recording without further interacting: just plug in a USB drive 
# or insert a CDRW, and the process starts.
# 
# Wait a minute... this sounds like something that fadecut can do!
# 
# That is correct. So why did I do it?
# 
# Fadecut is a great programms, no question about it! 
# 
# But soon after I started to use it, I realized it did not quite 
# fit my personal needs. So I started to write a small script that would
# do the every day work for me. It started with just 5 lines of code 
# for a cron job that downloaded a few hours of songs from a radio station 
# and burned them onto a CD, so I could enjoy the music the next day while
# driving my truck, without getting bored and annoyed by being forced
# to listen to the "heavy rotation" loop that most FM radio station 
# transmit these days and that simply drive my mad. I hate hearing the
# same set of songs in the same order three times a day!
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
# ***********************************************************************
# And last but by no means least I'd like to thank the author of fadecut 
# for the great inspiration: 
# 
# T h a n k   y o u !!! :)
# 
# **********************************************************************
# inrarec is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
# 
# inrarec is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details:
# <http://www.gnu.org/licenses/>.
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
# For this to work, you need a functioning mail system!
#
EMAIL=""

#
# Configuration directory:
#
RCDIR="$HOME/.inrarec/"

#
#
# Which file contains names and titles of unwanted artists and songs?
#
DONTLIKE="$RCDIR/dontlike"

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
# - the third example excludes a specific song by any artist.
# 
# So don't include a line saying "* - *". :)
#

# 
# profile dir
#
PROFILEDIR="$RCDIR/profiles"

# 
# The profiles that this script uses are identical to the ones that 
# fadecut uses. If you have fadecut profiles in use, you can even set
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
FADE_OUT=4
TRIM_BEGIN=1
TRIM_END=2
# ---------------------- cut here ---------------------
#
# Note: the above settings are taken as defaults, if you 
# call the program without "-p" option.

#
# streamripper:
# Options for streamripper, see "man streamripper". 
# Can be set in each profile, to use different options per station.
#
STREAMRIPPER_OPTS="-o always -T -k 1 -s --with-id3v1"

# Codesets:
#
# Which codeset does your filesystem use? 
#
CSFS="UTF-8"
#
# Note: I highly recomment to use UTF8 as the default locale on your system!
# If you're not stuck in the previous century, there's no need to use any 
# other locale any more!


#
# Which codeset is to be used to set ID3 tags?
# If you set this to UTF, be sure your mp3 player can display UTF8 characters!
#
CSID3="iso-8859-1"

# 
# Which codeset is to be used for meta-data?
#
CSMETA="UTF-8"

#
# Default limit for downloading, can be set via command line option. 
# Can also be set in each profile, to set a differnt limit per station.
#
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

# Do you want to keep streamripper's orinal downloads? (= Untouched by ffmpeg)
# Can be overwritten/set via command line option "-original".
# Can be set in each profile, to use different settings per station.
#
KEEPORIG="false"

# Do you want to keep the complete working director, including all 
# sub-directories like "incomplete"?
#
# Can be set via command line option "-KWD", and can also be set in 
# each profile, to use different settings per station.
# 
KEEPWORKINGDIR="false"
#


#
# Base dir to be used for recording, can be set via "-b <director>".
# Can also be set in each profile, to use a different directory per station.
#
RECBASEDIR=$HOME/internetradio

#
# Which file contains recordings that already have been burned onto a CD?
# This file simply prevents burning the same recording again and again,
# when a "headless" machine is used. (Doesn't really need to be changed!)
#
BURNED="$RCDIR/burned"

#
# Maximum number of recordings? (To prevent flooding the hard disk!)
# Value of zero means no limit!
#
# Note: this number counts for all recordings, not per station!
#
# MAXRECORDINGS=0
MAXRECORDINGS=7


#
# Which binaries to use for burning a CD?
CDRECORD=/opt/schily/bin/cdrecord
MKISOFS=/opt/schily/bin/mkisofs
#
# If you want to use the system's default binaries, just uncomment the 
# following two lines:
#CDRECORD=$(which cdrecord)
#MKISOFS=$(which mkisofs)
#
# But keep in mind that although "wodim", the fork of "cdrecord", provides
# the binaries "/usr/bin/cdrecord" and "/usr/bin/mkisofs", those binaries
# behave diffently than the original "cdrecord" package and sometimes
# "wodim" won't burn a CD from the command line. So I highly recomment to
# install the "cdrecord" package provided on http://cdrecord.org/
#

# The CD-RW device:
DEVICE=/dev/sr0

# Copying to USB drive:
#
# The following settings are important, if you want to use udev to burn
# a CD, as soon as you insert a blank disk, or if you want to copy recorded
# music to a USB drive. See below.
#
#
# Mounting point for the USB drive, that the recording is to be copied to.
# If empty, nothing will be copied!
#
# Can be set in each profile, to use different USB devices per station.
#
# USBMUSIC=""
USBMUSIC=/mnt/music/

# Do you want the recorded sessions to be copied into a specific 
# sub-directory? If not, just leave the variable empty.
#
# USBDIR=""
USBDIR=internetradio

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
# 
# Note: this is a global setting for udev to work, 
# it can't be set per station!
# 
VOLUME="One for the road"


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
# Then, as soon as you insert the prepared USB drive or CDRW, 
# the recording will be automatically be copied/burned. 
# 
# This is espacially handy on a headless machine, and that's the reason 
# why I included this feature in the first place! :)
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

${0##*/} [-p profile] [limit] [-t targetdir]  [-k] [-usb] [-cd] [-korig] [-kwd]

-p profile	which profile to use (required)
-b basedir	which basedir to use for working and storing (optional)
-t targetdir	alternative dir to store recording after trimming (optional)
-cd		burn to cd after ripping and trimming (optional)
-usb		copy to predefined USB drive after trimming (optional)
-korig		keep the original downloads (optional)
-kwd		keep the complete working dir (optional)

limit can be set like the following examples:

-s 60		60 seconds
-m 30		30 minutes
-h 12		12 hours
-d 2 		2 days
-M 50		500 MB
-G 2		2 GB

Default limit:	700MB

Alternate usage (use with caution!):

${0##*/} -all2usb | -burnlatest | -burn <dir> | -trim <dir> <dest>

-all2usb		copy *all* recordings to a predefined USB drive.
-burnnewest		burn the newest recording onto a CD-RW.
-burnoldest		burn the oldest recording onto a CD-RW. 
-burn <dir>		burn <dir> onto a CR-RW.
-trim <source> <dest>	process the songs in <source> and 
			write them to <dest>. This option can be used, 
			e.g. if the program crashed after download but before 
			editing the songs.
			CAUTION: existing files in <dest> will be overwritten!

EOF
exit
}


rsync_all()
{
  IFS=$TMPIFS

  if [ ! -x $(which rsync) ]
  then

    echo
    echo Error: rsync not found or not executable! 
    echo 
    echo Downloading songs is still possible, but if you want to copy them
    echo to some other place \(e.g. a USB drive\), rsync is required!
    echo
  
  else

    free=$(df "$USBMUSIC" --output=avail | tail -1)
    needed=$(du -s "$RECBASEDIR/" | cut -f1)
    ## turn contents into numerical values:
    free=$(( $free + 1 ))
    needed=$(( $needed + 1 ))

    if [ $needed -gt $free ];
    then
	echo
	echo Not enough space left on USB device! 
	echo
    else

      mount $USBMUSIC

      for vz in "$RECBASEDIR"/[a-zA-Z0-9]*;
      do
	# do not sync while working dir exists!
	if [ ! -d "$RECBASEDIR"/".${vz##*/}" ]
	then
	  nice -n 19 rsync -a --ignore-existing --delete --exclude ".*/" --exclude ".*" "$vz" "$USBMUSIC/$USBDIR/"
	fi
      done # for vz in "$RECBASEDIR"/[a-zA-Z0-9]*
      
      umount $USBMUSIC

    fi # [ $needed -gt $free ];

  fi # [ ! -x $(which rsync) ]

  IFS=$OLDIFS

}

cdrw()
{

  SRC="$1"
  VOLUME="$2"

  if [ ! -x $CDRECORD ]
  then

    echo
    echo Error: cdrecord not found or not executable! 
    echo 
    echo Downloading songs is still possible, but if you want to burn them
    echo to a CDRW, cdrecord is required! 
    echo

  elif [ ! -x $MKISOFS ]
  then	

    echo
    echo Error: mkisofs not found or not executable! 
    echo 
    echo Downloading songs is still possible, but if you want to burn them
    echo to a CDRW, mkisofs is required! 
    echo
 
  else

    IFS=$TMPIFS	

    if [ "xxx$SRC" = "xxx" ]	
    then	
	    echo	
	    echo I\'ll stay cool because there\'s nothing to burn...	
	    echo	
	    return	
    fi	

    if $CDRECORD -minfo | grep -E 'Mounted media type: +CD-RW';	
    then	
      echo	
      echo Blanking the disc...	
      echo	

      $CDRECORD dev=$DEVICE -force blank=fast -gracetime=0	
      
      echo	
      echo Burning contents of \"$SRC\"...	
      echo	

      GRAFT=${SRC%*/} # strip trailing slash
      GRAFT=${GRAFT##*/} # strip full path	

      ts=$($MKISOFS -quiet -print-size "$SRC"/)s	
      $MKISOFS -quiet -V "$VOLUME" -J -R -graft-points "$GRAFT"="$SRC" \
      | $CDRECORD dev=$DEVICE -sao driveropts=burnfree \
      -gracetime=0 -data -eject fs=16m -tsize=$ts -

      echo	
      echo Finished!	
      echo	
      
      [ $? -eq 0 ] && echo "$SRC" >> $BURNED	

    else	
	    echo	
	    echo No CD-RW available!	
	    echo	
    fi # $CDRECORD -minfo | grep -E 'Mounted media type: +CD-RW';	

    IFS=$OLDIFS	
  fi
}

find2burn()
{	
 
  touch "$BURNED"
  found=""
  ALLRECORDINGS=$(find $RECBASEDIR/ -name '[!.]* - 20[0-9][0-9]-[0-9][0-9]-[0-9][0-9]' -type d -print \
		  | sed -e 's/^.* \([[:graph:]]\{1,\}\)$/\1 &/' \
		  | sort $SORTORDER \
		  | sed -e 's/^\([[:graph:]]\{1,\}\) //')
 
  IFS=$TMPIFS
	
  for recording in $ALLRECORDINGS;
  do

    #echo $recording ; echo

    workingdir="$RECBASEDIR/.${recording##*/}"
    tocheck=$(grep "${recording##*/}" "$BURNED")
    if [ "xxx$tocheck" != "xxx" ]
    then
      # echo ..."$recording" has been burned before...
      continue
    elif [ -e "$recording" -a ! -e "$workingdir" ]
    then
      echo "$recording"
      break
    fi
  done

  IFS=$OLDIFS
}

checkdontlike()
{
    
  local ARTIST="$1"
  local TITLE="$2"

  thissong=$(grep -i "\* - $TITLE" $DONTLIKE)
  thisartist=$(grep -i "$ARTIST - \*" $DONTLIKE)
  thissongbythisartist=$(grep -i "$ARTIST - $TITLE" $DONTLIKE)
  # Most likely this three greps could be melted into one, but I did not
  # want to make it look too complicated.

    if [ "xxx${thissong}" != "xxx" ]
    then
	echo I don\'t like this song!
    elif [ "xxx${thisartist}" != "xxx" ]
    then
	echo I don\'t like this artist!
    elif [ "xxx${thissongbythisartist}" != "xxx" ]
    then
	echo I don\'t like this song by this artist!
    else
	echo I like this song!
    fi
  
}

checkcopy2usb()
{

  local USBMUSIC="$1"

  if [ "$COPY2USB" = "true" ]
  then
    mount "$USBMUSIC"

    if ! mountpoint -q "$USBMUSIC";
    then
	echo
	echo USB-Target can not be mounted!
	echo Songs will not be copied to USB!
	echo
	COPY2USB="false"
    else
      USBTARGETDIR="$USBMUSIC/${COMMENT} - ${DATE}"
      mkdir -p "$USBMUSIC"/"${COMMENT} - ${DATE}"

    fi

  fi # [ "$COPY2USB" = "true" ]
}

checkbasedir()
{

  local RECBASEDIR="$1" 
 
  if [ "xxx$RECBASEDIR" = "xxx" ]
  then
    RECBASEDIR=$HOME/tmp/
  fi

  if ! mkdir -p "$RECBASEDIR" ;
  then 
    echo "$RECBASEDIR" does not exist and can not be created! Exiting...
    echo
    exit
  fi
}

checkworkingdir()
{

  local RECBASEDIR="$1"
  local COMMENT="$2"
  local DATE="$3"

  WORKINGDIR="$RECBASEDIR/.${COMMENT} - ${DATE}"

  if [ "$USETHEFORCE" = "false" ]
  then

      if [ -d "$WORKINGDIR" ]
      then

	  echo
	  echo Directory \"$WORKINGDIR\" already exists. Is there a recording running?
	  echo 
	  echo Maybe you should use the force, Luke...
	  echo
	  exit
      fi

  fi # [ "$USETHEFORCE" = "false" ]

  
  if ! mkdir -p "$WORKINGDIR";
  then
	      echo
	      echo "$WORKINGDIR" does not exist and can not be created! Exiting...
	      echo	
	      exit
  fi

}

checkmaxrec()
{

    local RECBASEDIR="$1"

    if [ "$USETHEFORCE" = "false" ]
    then
	RECORDINGS=$(find "$RECBASEDIR/" -type d -name "[!.]* - 20[0-9][0-9]-[0-9][0-9]-[0-9][0-9]" | wc -l)
	# I know that this find command is limited to the years 2001 - 2099, 
	# but I don't assume anyone will use this script after 2099 any more. ;)
    else

	# if argument "-f" is used, we don't check for free disk space!
	RECORDINGS=0

     fi


    # convert into numerical values:
    RECORDINGS=$(( $RECORDINGS + 0 ))
    MAXRECORDINGS=$(( $MAXRECORDINGS + 0 )) 
    
    if [ $RECORDINGS -ge $MAXRECORDINGS ]
    then
	echo
	echo Too many recordings found: 
	echo check $RECBASEDIR and delete unnecessary recordings!
	echo 
	echo Maybe you should use the force, Luke...
	echo
	exit
    fi # [ $RECORDINGS -ge $MAXRECORDINGS ]

}

checktargetdir()
{
  local TARGETDIR="$1"

  if [ "xxx$TARGETDIR" = "xxx" ]
  then
      TARGETDIR="$RECBASEDIR/${COMMENT} - ${DATE}"
  fi
  
  if ! mkdir -p "$TARGETDIR";
  then 
    echo "$TARGETDIR" does not exist and can not be created! Exiting...
    echo
    exit
  fi
}


dostreamripper()
{
  echo
  echo $START: Starting recording in \"${WORKINGDIR}\"...
  echo

  mkdir -p "$WORKINGDIR"/{new,error,incomplete,orig}

  streamripper $STREAM_URL $STREAMRIPPER_OPTS \
	--codeset-filesys=$CSFS \
	--codeset-id3=$CSID3 \
	--codeset-metadata=$CSMETA \
	$SRLIMIT -d "$WORKINGDIR"

  SR_EX=$?

  if [ ! $SR_EX -eq 0 ]
  then	
    echo
    echo Streamripper exited with error code $SR_EX!
    echo
    exit
  fi

  echo
  echo Download finished!
  echo 

}

checkrcdir()
{ 
    local RCDIR="$1"
 
    if [ ! -d "$RCDIR" ]
    then
      echo
      echo Can\'t load configuration, because $RCDIR does not exist! Exiting...
      echo
      exit
    fi
}

umountusbdrive()
{
  if mountpoint -q "$USBMUSIC";
  then
   umount "$USBMUSIC" 
  fi
}

trimsongs()
{

  local WORKINGDIR="$1"
  local TARGETDIR="$2"
   
  if [ ! -d "$WORKINGDIR" ]
  then
    echo $WORKINGDIR does not exist! Exiting...
    exit
  fi

  checktargetdir "$TARGETDIR"

  IFS=$TMPIFS
 
    NUMBER=$(ls -1 "$WORKINGDIR"/*.* | wc -l)
    DIGITS=${#NUMBER}
    # sort by reverse date (oldest file first):
    ALLFILES=$(ls -1rt "$WORKINGDIR/"*.*)
    if [ "xxx$ALLFILES" = "xxx" ]
    then	
      echo There are no songs to work on! Exiting...
      exit
    fi

    i=1

    for FILE in $ALLFILES
    do

      ARTIST=$(ffprobe -v error -show_entries format_tags=artist -of default=noprint_wrappers=1:nokey=1 "$FILE") 
      TITLE=$(ffprobe -v error -show_entries format_tags=title -of default=noprint_wrappers=1:nokey=1 "$FILE")
      #SONG="${FILE##*/}"
      SONGNAME="${FILE##*/}" # stripping path
      SONGNAME="${SONGNAME%.*}" # stripping extension

      TASTE=$(checkdontlike "$ARTIST" "$TITLE")

      if [ "$TASTE" = "I like this song!" ]
      then
	  
	  TIMESTAMP="$(date -R -r "$FILE")"
	  LENGTH=$(ffprobe -v error -show_entries format=duration -of default=noprint_wrappers=1:nokey=1 "$FILE")
	  LENGTH=${LENGTH%%.*}
	  TRIMLENGTH=$((LENGTH - TRIM_BEGIN - TRIM_END))
	  FADE_OUT_START=$((TRIMLENGTH - FADE_OUT))
	  NUMBER=$(printf "%0${DIGITS}d\n" $i)
	  DEST="$TARGETDIR/$NUMBER - $SONGNAME".mp3
	  DOCOPY=""
	  FFMPEGOUT="\"$DEST\""

	  if [ "$COPY2USB" = "true" ]
	  then
	      USBDEST="$USBTARGETDIR/$NUMBER - $SONGNAME".mp3
	      if [ "$TEATIME" = "true" ]
	      then
		  FFMPEGOUT="- | tee \"$DEST\" \"$USBDEST\" >/dev/null"
	      else
		  DOCOPY="(cp \"$DEST\" \"$USBDEST\")&"
	      fi
	  fi

	  ANYTOWAVE="ffmpeg -hide_banner -loglevel 0 -nostats -i \"$FILE\" -f wav -"
	  WAVETOMP3="ffmpeg -hide_banner -loglevel 0 -nostats -i - -ss $TRIM_BEGIN -t $TRIMLENGTH -af afade=t=in:ss=0:d=$FADE_IN,afade=t=out:st=$FADE_OUT_START:d=$FADE_OUT -f mp3 $FFMPEGOUT"

	  TOTALCMD="$ANYTOWAVE | $WAVETOMP3"

	  #
	  # Question: 
	  # Why am I piping ffmpeg into ffmpeg? 
	  #
	  # Answer: 
	  # If ffmpeg is to cut and fade a media file, it needs 
	  # to know the lenght of the file *before* it can do its work.
	  # This is a bit of a problem with certain formats like aac. 
	  # By using two instances of fadecut these problems can be 
	  # bypassed, because the first ffmpeg converts any input format
	  # to wave format, piping it into the second instance, which can
	  # do the cutting and fading and the final converting to mp3.
	  
	  echo $SONGNAME -\> fading out...
	  
	  #echo "$TOTALCMD"
	  #echo "$DOCOPY"
	  eval "$TOTALCMD"
	  eval "$DOCOPY"
	  
	  # restore original timestamp:
	  touch -c -d "$TIMESTAMP" "$DEST" 

	  # you can't do a "touch -d" to /dev/null, so check first:
	  test -f "$USBDEST" && touch -c -d "$TIMESTAMP" "$USBDEST"

	  # next, please!
	  i=$(( i + 1))

      else
	      echo $SONGNAME: -\> deleting, because $TASTE!
	      rm -f "$FILE"
      fi # [ "$TASTE" = "I like this song!" ]

  done # for SONG in $ALLSONGS

  stty sane # needed after piping ffmpeg into ffmpeg. WHY???
  IFS=$OLDIFS
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

if [ ! -x $(which ffmpeg) ]
then
  echo
  echo Error: ffmpeg not found or not executable! 
  echo 
  exit
fi

if [ -x $(which tee) ]
then
  TEATIME="true"
else
  TEATIME="false"
  echo
  echo Notice: tee not found or not executable! 
  echo 
  echo This program can still be used, but witout \"tee\"
  echo it takes much longer to copy recorded songs to USB.
  exit
fi

renice -n 19 $$

####
# Date format, used as part of directory naming - DO NOT CHANGE!!!
DATE=$(date "+%F")
START=$(date "+%F %X")
BURN2CD="false"
COPY2USB="false"
USETHEFORCE="false"

# command line arguments:
while [ $# -gt 0 ];
do
   case "$1" in
	"-b")
		if [ "xxx$2" = "xxx" ]
		then 
		    echo 
		    echo Option -b needs an argument!
		    help
		    exit
		fi
		RECBASEDIR="$2"
		shift 2
		;;
	"-kwd")
		KEEPWORKINGDIR="true"
		shift
		;;
	"-korig")
		KEEPORIG="true"
		shift
		;;
	"-t")
		if [ "xxx$2" = "xxx" ]
		then 
		    echo 
		    echo Option -t needs an argument!
		    help
		    exit
		fi
		TARGETDIR="$2"
		shift 2
		;;
	"-r")
		if [ "xxx$2" = "xxx" ]
		then 
		    echo 
		    echo Option -r needs an argument!
		    help
		    exit
		fi
		RECBASEDIR="$2"
		mkdir -p "$RECBASEDIR"
		shift 2
		;;
	
 	"-p")
		PROFILE="$2"
		if [ ! -e "$PROFILEDIR"/"$PROFILE" ]
		then
		  echo
		  echo Profile \"$PROFILE\" does not exist!
		  echo
		  exit
		else
		  . "$PROFILEDIR"/"$PROFILE"
		fi
		shift 2
		;;
	"-M")
		if [ "xxx$2" = "xxx" ]
		then 
		    echo 
		    echo Option -M needs an argument!
		    help
		    exit
		fi
		SRLIMIT="-M $2"
		shift 2
		;;
	"-G")
		if [ "xxx$2" = "xxx" ]
		then 
		    echo 
		    echo Option -G needs an argument!
		    help
		    exit
		fi
		SRLIMIT="-M $(( $2 * 1000))"
		shift 2
		;;
	"-s")
		if [ "xxx$2" = "xxx" ]
		then 
		    echo 
		    echo Option -s needs an argument!
		    help
		    exit
		fi
		SRLIMIT="-l $2"
		shift 2
		;;
	"-m")
		if [ "xxx$2" = "xxx" ]
		then 
		    echo 
		    echo Option -m needs an argument!
		    help
		    exit
		fi
		SRLIMIT="-l $(( $2 * 60))"
		shift 2
		;;
	"-h")
		if [ "xxx$2" = "xxx" ]
		then 
		    echo 
		    echo Option -h needs an argument!
		    help
		    exit
		fi
		SRLIMIT="-l $(( $2 * 60 * 60))"
		shift 2
		;;
	"-d")
		if [ "xxx$2" = "xxx" ]
		then 
		    echo 
		    echo Option -d needs an argument!
		    help
		    exit
		fi
		SRLIMIT="-l $(( $2 * 60 * 60 * 24))"
		shift 2
		;;
        "-cd")
		BURN2CD="true"
		echo
		echo Songs will be burned to CD-RW after download and trimming.
		echo Make sure, there is a re-writable disk inserted!
		echo
            	shift
            	;;
        "-usb")
		COPY2USB="true"
		echo
		echo Songs will be copied to USB after download and trimming.
		echo Make sure, the device is plugged in!
		echo
		shift
            	;;
	"-udev")
		# script has been started by udev
		#
		# The reason for using the "at" command here is that udev
		# doesn't run programms that last too long. Burning
		# a CD or using rsync definately is too long!
		#
		if [ "$2" = "cd" ]
		then
		     echo "$0 -burnoldest" | /usr/bin/at now + 1 minute	
		     exit			     
		elif [ "$2" = "usb" ]
		then
		     echo "$0 -all2usb" | /usr/bin/at now + 1 minute	
		     exit			     
		else
		    echo
		    echo Unknown pair of arguments: "$1" "$2"
		    echo
		    exit
		fi
		;;
	 "-burnnewest")
		 SORTORDER="-r"
		 cdrw "$(find2burn)" "$VOLUME"
		 exit
		 ;;
	"-burnoldest")
		 SORTORDER=""
		 cdrw "$(find2burn)" "$VOLUME"
		 exit
		 ;;
	"-burn")
		cdrw "$2" "$VOLUME"
		exit
		;;
	"-all2usb")
		rsync_all 
		exit
		;;
	  "-f")
		# don't check for another running instance
		USETHEFORCE="true"
		shift
		;;
	"-trim")
		checkcopy2usb "$USBMUSIC"
		trimsongs "$2" "$3"
		umountusbdrive
		exit
		;;
	  *)
		help
		exit
                ;;
  esac
done

checkrcdir "$RCDIR"

checkmaxrec "$RECBASEDIR"

checkcopy2usb "$USBMUSIC"

checkbasedir "$RECBASEDIR"

checkworkingdir "$RECBASEDIR" "$COMMENT" "$DATE"

checktargetdir "$TARGETDIR"

dostreamripper

trimsongs "$WORKINGDIR" "$TARGETDIR"

if [ "$BURN2CD" = "true" ]
then
  echo 
  echo Burning \"$TARGETDIR\" to CDRW...
  echo
  cdrw "$TARGETDIR" "$VOLUME"
fi

if [ "$COPY2USB" = "true" ]
then
  umount $USBMUSIC
  echo
  echo All songs have been copied to $USBTARGETDIR as well. Enjoy!
  echo
fi

if [ "$KEEPORIG" = "true" ]
then
  mkdir -p "$TARGETDIR"/orig
  mv "$WORKINGDIR"/*.* "$TARGETDIR"/orig/
  echo
  echo You will find the original downloads in \"$TARGETDIR/orig/\"!
  echo
fi

if [ "$KEEPWORKINGDIR" = "true" ]
then
  echo
  echo Working directory \"$WORKINGDIR\" will not be deleted!
  echo
else
   rm -rf "$WORKINGDIR"
fi

if [ "xxx$EMAIL" != "xxx" ]
then

    if [ ! -x $(which mail) ]
    then
      echo
      echo Error: mail command not found or not executable! 
      echo 
      echo Downloading songs is still possible, but if you want to be notified
      echo by e-mail afterwards, a functioning mail system is required!
      echo
    else
      echo
      echo ... on \"$TARGETDIR/\" | mail -s "Thank you for the music..." $EMAIL
      echo
    fi

else

  FINISH=$(date "+%F %X")
  SECONDS=$(($(date "+%s" --date="-d $FINISH") - $(date "+%s" --date="-d $START")))
  TDIFF=$(($(date "+%s" --date="-d $FINISH") - $(date "+%s" --date="-d $START")))
  echo
  echo $FINISH: Done! The job took me $(printf '%02dh:%02dm:%02ds\n' $(($TDIFF/3600)) $(($TDIFF%3600/60)) $(($TDIFF%60))). 
  echo Check for new music in \"$TARGETDIR/\" and enjoy!
  echo

fi

