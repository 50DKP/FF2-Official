#!/bin/bash -e

ARGS=$(getopt -o "siaqnv" -l "update-sourcemod,update-includes,update-all,quiet,sourcemod-version:,no-compile,verbose" -n "build.sh" -- "$@");
eval set -- "$ARGS";

while [ $# -gt 0 ]; do
	case "$1" in
		-s|--update-sourcemod)
			SOURCEMOD=true;
			shift;
			;;
		-i|--update-includes)
			INCLUDES=true;
			shift;
			;;
		-a|--update-all)
			SOURCEMOD=true;
			INCLUDES=true;
			shift;
			;;
		-q|--quiet)
			QUIET=true;
			shift;
			;;
		--sourcemod-version)
			shift;
			SMVERSION=$1;
			shift;
			;;
		-n|--no-compile)
			NOCOMPILE=true;
			shift;
			;;
		-v|--verbose)
			VERBOSE=true;
			shift;
			;;
		--)
			shift;
			break;
			;;
	esac
done

if [ $QUIET ]; then
	alias wget="wget -q"
fi

if [ $SOURCEMOD ]; then
	if [ -z $SMVERSION ]; then
		SMVERSION=$(wget http://sourcemod.net/smdrop/ -O - | grep " 1\." | sed 's/^.*"1\./1\./;s/\/".*$//' | tail --lines=1)
		echo "--sourcemod-version unspecified, using $SMVERSION instead"
	fi

	wget http://sourcemod.net/smdrop/$SMVERSION/ -O - | grep "\.tar\.gz" | sed 's/^.*"sourcemod/sourcemod/;s/\.tar\.gz".*$/.tar.gz/' | tail --lines=1 > sourcemod
	wget --input-file=sourcemod --base=http://sourcemod.net/smdrop/$SMVERSION/
	tar -xzf $(cat sourcemod)
	rm $(cat sourcemod)
	rm sourcemod
fi

cd addons/sourcemod/scripting/
if [ $INCLUDES ]; then
	wget "http://hg.limetech.org/projects/tf2items/tf2items_source/raw-file/tip/pawn/tf2items.inc" -O include/tf2items.inc
	wget "http://www.doctormckay.com/download/scripting/include/morecolors.inc" -O include/morecolors.inc
	wget "http://hg.limetech.org/projects/steamtools/raw-file/tip/plugin/steamtools.inc" -O include/steamtools.inc
	wget "https://bitbucket.org/GoD_Tony/updater/raw/default/include/updater.inc" -O include/updater.inc
	wget "https://raw.githubusercontent.com/Flyflo/SM-Goomba-Stomp/master/addons/sourcemod/scripting/include/goomba.inc" -O include/goomba.inc
	wget "https://forums.alliedmods.net/attachment.php?attachmentid=115795&d=1360508618" -O include/rtd.inc
	wget "https://forums.alliedmods.net/attachment.php?attachmentid=116849&d=1377667508" -O include/tf2attributes.inc
	chmod +x spcomp
	mkdir -p compiled compiled/freaks
fi

if [ -z $NOCOMPILE ]; then
	./compile.sh freak_fortress_2.sp freaks/*.sp
	cd compiled/freaks
	rename -f 's/.smx/.ff2/' *.smx
fi
