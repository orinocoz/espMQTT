#!/bin/bash
set -e

increment_version ()
{
  declare -a part=( ${1//\./ } )
  declare    new
  declare -i carry=1

  for (( CNTR=${#part[@]}-1; CNTR>=0; CNTR-=1 )); do
    len=${#part[CNTR]}
    new=$((part[CNTR]+carry))
    part[CNTR]=${new}
#    [ ${#new} -gt $len ] && carry=1 || carry=0
#    [ $CNTR -gt 0 ] && part[CNTR]=${new: -len} || part[CNTR]=${new}
    break;
  done
  new="${part[*]}"
  new="${new// /.}"
  echo $new
} 

build ()
{
  echo ''
  echo '###################################################################################################'
  echo BUILDING $targetname VERSION $VERSION...
  echo '###################################################################################################'
  echo ''
  
  echo '#define '$targetname > espMQTT_buildscript.h
  echo '#define ESPMQTT_VERSION "'$VERSION'"' >> espMQTT_buildscript.h
  arduino --board $BOARD --verify --pref build.path=./builds/tmp --pref build.extra_flags=' -DESP8266 -DWEBSOCKET_DISABLED=true -DASYNC_TCP_SSL_ENABLED -DUSE_HARDWARESERIAL -DESPMQTT_BUILDSCRIPT ' --preserve-temp-files espMQTT.ino
  echo '' > espMQTT_buildscript.h

  if [ $? -ne 0 ]
  then 
  echo ''
  echo '###################################################################################################'
  echo BUILDING $targetname VERSION $VERSION FAILED!!!
  echo '###################################################################################################'
  echo ''
  exit $?
  fi

  echo $VERSION > ./builds/v$VERSION/$targetname.version
  mv ./builds/tmp/espMQTT.ino.bin './builds/v'$VERSION'/'$targetname'_'$VERSION.bin

  echo ''
  echo '###################################################################################################'
  echo BUILDING $targetname VERSION $VERSION FINISHED.
  echo '###################################################################################################'
  echo ''
}

git update-index --assume-unchanged espMQTT_buildscript.h

VERSION=$(git describe --tags | sed 's/v//')
DIFFERENCE=$(git diff | wc -w)
TARGET=$1

if [ -z "$TRAVISBUILD" ]
then
	if [ $DIFFERENCE -eq 0 ] 
	then
		if [[ $1 == "release" ]]
		then
			TARGET=$2
			# IF CURRENT VERSION CONTAINS A - (SO NOT LATEST TAG) CREATE NEW VERSION TAG
			if [[ $VERSION == *"-"* ]]
			then
				VERSION=$(echo $VERSION | sed 's/-.*//' | sed 's/v//')
				VERSION=$(increment_version $VERSION)
				git tag v$VERSION
				git push --tags
				VERSION=$VERSION
			fi
		fi
	else
		VERSION=$VERSION-DIRTY-$(date +%s)
	fi
fi

VERSION=$VERSION

mkdir -p ./builds/v$VERSION
rm -rf ./builds/tmp
mkdir ./builds/tmp

echo $VERSION > version

declare -a TARGETS=("ESPMQTT_DDM18SD" "ESPMQTT_WEATHER" "ESPMQTT_AMGPELLETSTOVE" "ESPMQTT_BATHROOM" "ESPMQTT_BEDROOM2" "ESPMQTT_OPENTHERM" "ESPMQTT_SMARTMETER" "ESPMQTT_GROWATT" "ESPMQTT_SDM120" "ESPMQTT_WATERMETER" "ESPMQTT_DDNS" "ESPMQTT_GENERIC8266" "ESPMQTT_MAINPOWERMETER" "ESPMQTT_NOISE" "ESPMQTT_SOIL" "ESPMQTT_DIMMER" "ESPMQTT_OBD2")
BOARD=esp8266com:esp8266:nodemcuv2
for targetname in "${TARGETS[@]}"
do
	if [ "$TARGET" == "" ]
	then
		build
	else
		if [ "$TARGET" == "$targetname" ]
		then
			build
		fi
	fi
done

declare -a TARGETS=("ESPMQTT_DUCOBOX" "ESPMQTT_SONOFFS20" "ESPMQTT_SONOFFBULB" "ESPMQTT_SONOFFPOWR2" "ESPMQTT_GARDEN" "ESPMQTT_SONOFF_FLOORHEATING" "ESPMQTT_IRRIGATION" "ESPMQTT_BLITZWOLF" "ESPMQTT_SONOFF4CH" "ESPMQTT_SONOFFDUAL" "ESPMQTT_SONOFFS20_PRINTER" "ESPMQTT_SONOFFPOW" "ESPMQTT_QSWIFIDIMMERD01" "ESPMQTT_QSWIFIDIMMERD02" "ESPMQTT_ZMAI90")
BOARD=esp8266com:esp8266:esp8285
for targetname in "${TARGETS[@]}"
do
	if [ "$TARGET" == "" ]
	then
		build
	else
		if [ "$TARGET" == "$targetname" ]
		then
			build
		fi
	fi
done


git checkout -f espMQTT_buildscript.h

