#!/bin/bash
set -e
PLATFORM=$(cat PLATFORM_OVERRIDE)
if [[ $PLATFORM != 1 ]] && [[ $PLATFORM != 5 ]]; then PLATFORM=${1-1}; fi
if [[ $PLATFORM != 1 ]] && [[ $PLATFORM != 5 ]]; then
	echo "Usage: 1 for Linux (Default), 5 for XCompiling for Windows"
	exit 1
fi
pushd .
cd "$(dirname "${0}")/.."


##### Configure and Make
cd OneLife/server
./configure $PLATFORM

make

cd ../..


##### Create Game Folder
mkdir -p output
cd output

FOLDERS="objects transitions categories tutorialMaps"
TARGET="."
LINK="../OneLifeData7"
../miniOneLifeCompile/util/createSymLinks.sh $PLATFORM "$FOLDERS" $TARGET $LINK


cp -Rf ../OneLife/gameSource/settings ./settings

cp ../OneLife/server/firstNames.txt .
cp ../OneLife/server/lastNames.txt .
cp ../OneLife/server/wordList.txt .

cp ../OneLifeData7/dataVersionNumber.txt .


##### Copy to Game Folder and Run
if [[ $PLATFORM == 5 ]]; then mv ../OneLife/server/OneLifeServer.exe .; fi
if [[ $PLATFORM == 1 ]]; then mv ../OneLife/server/OneLifeServer .; fi

popd
./runServer.sh