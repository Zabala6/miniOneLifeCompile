#!/bin/bash
cd "$(dirname "${0}")/.."
COMPILE_ROOT=$(pwd)
OUTPUT=$COMPILE_ROOT/output
ONE_LIFE=$COMPILE_ROOT/OneLife
ONE_LIFE_DATA=$COMPILE_ROOT/OneLifeData7
ONE_LIFE_SERVER=$ONE_LIFE/server
GAME_SOURSE=$ONE_LIFE/gameSource
MINI_ONE_LIFE_COMPILE=$COMPILE_ROOT/miniOneLifeCompile

DISCORD_SDK_PATH="$COMPILE_ROOT/dependencies/discord_game_sdk"
MINOR_GEMS_PATH="$COMPILE_ROOT/minorGems"

Help(){
    echo "---------------------------------------"
    echo "Compiler for client, server and editor."
    echo
    echo "Important: You have to be in miniOneLifeCompile"
    echo
    echo "Syntax: syntaxTemplate [-h|-c] [-p]"
    echo "options:"
    echo " -h     Print this help."
    echo " -p     Platform 1: Linux, 5: Windows."
    echo " -c     Compiler value is sum of this values."
    echo "        1 - client compile"
    echo "        2 - server compile"
    echo "        4 - editor compile"
    echo "example:"
    echo " -c 5 -p 1: compile client and editor for platform Linux"
    echo " -c 3 -p 5: compile client and server for platform Windows"
    echo "---------------------------------------"
}

main(){
    get_options "$@"
    check_input
    compiler_switch
}

get_options(){
    while getopts ":hc:p:" option; do
        case $option in
            h)
                Help
                exit;;
            c) 
                export COMPILE=$OPTARG;;
            p)
                export PLATFORM=$OPTARG;;
            \?)
                echo "Error: Invalid option"
                exit;;
        esac
    done
}

check_input(){
    if [ -z "$COMPILE" ]; then
        echo "Error: Compile option wasn't satisfied"
        exit
    elif ! [ "$COMPILE" -ge 1 ] || ! [ "$COMPILE" -le 7 ];then
        echo "Error: Compile option is beyond valid range 1 to 7"
        exit
    fi

    if [ -z "$PLATFORM" ]; then
        PLATFORM=1
        echo "Warning: Platform option wasn't satisfied. It was set to 1(Linux)."
    elif ! [ "$PLATFORM" -eq 1 ] && ! [ "$PLATFORM" -eq 5 ]; then
        echo "Error: Platform option is valid only for 1 and 5"
        exit
    fi
}

compiler_switch(){
    if (( ($COMPILE & 1) != 0 )); then
        echo "Compiling client ..."
        compile_client
    fi
    if (( ($COMPILE & 2) != 0 )); then
        echo "Compiling server ..."
        compile_server
    fi
    if (( ($COMPILE & 4) != 0 )); then
        echo "Compiling editor ..."
        compile_editor
    fi
}

compile_client(){
    configure_client

    make_client
    make_output_dir
    make_client_symLinks
    make_game_settings
    
    cp_sdl_win
    cp_clearCache_win
    cp $ONE_LIFE/{gameSource/reverbImpulseResponse.aiff,server/wordList.txt} $OUTPUT
    cp_game_version_number
    cp_discord_sdk
    cp_game
}

compile_server(){
    configure_server

    make_server
    make_output_dir
    make_server_symLinks
    make_game_settings

    cp $ONE_LIFE_SERVER/{firstNames.txt,lastNames.txt,wordList.txt} $OUTPUT
    cp_game_version_number
    cp_server
}

compile_editor(){
    configure_editor

    make_editor
    make_output_dir
    make_editor_symLinks
    make_game_settings

    cp $GAME_SOURSE/{us_english_60.txt,reverbImpulseResponse.aiff} $OUTPUT
    cp_game_version_number
    cp_sdl_win
    cp_editor
}

make_output_dir(){
    if ! [ -d $OUTPUT ];then
        mkdir $OUTPUT
    fi
}

make_game_settings(){
    if ! [ -d "$OUTPUT/settings" ];then
        cp -r $GAME_SOURSE/settings $OUTPUT/settings
    fi
}

make_client_symLinks(){
    make_main_data_symLinks
    make_secondary_data_symLinks
}

make_server_symLinks(){
    if ! [ -d $OUTPUT/tutorialMaps ];then
        TARGET="$OUTPUT"
        FOLDERS="objects transitions categories tutorialMaps"
        LINK="$ONE_LIFE_DATA"
        $MINI_ONE_LIFE_COMPILE/util/createSymLinks.sh $PLATFORM "$FOLDERS" $TARGET $LINK
    fi
}

make_editor_symLinks(){
    make_main_data_symLinks
    make_secondary_data_symLinks
}

make_main_data_symLinks(){
    if ! [ -d $OUTPUT/animations ];then
        TARGET="$OUTPUT"
        FOLDERS="animations categories ground music objects sounds sprites transitions"
        LINK="$ONE_LIFE_DATA"
        $MINI_ONE_LIFE_COMPILE/util/createSymLinks.sh $PLATFORM "$FOLDERS" $TARGET $LINK
    fi
}

make_secondary_data_symLinks(){
    if ! [ -d $OUTPUT/graphics ];then
        TARGET="$OUTPUT"
        FOLDERS="graphics otherSounds languages"
        LINK="$GAME_SOURSE"
        $MINI_ONE_LIFE_COMPILE/util/createSymLinks.sh $PLATFORM "$FOLDERS" $TARGET $LINK
    fi
}


make_client(){
    cd $GAME_SOURSE
    make
}

make_server(){
    cd $ONE_LIFE_SERVER
    make
}

make_editor(){
    cd gameSource
    ./makeEditor.sh
}

configure_client(){
    cd $ONE_LIFE
    if [ -d $DISCORD_SDK_PATH ]; then
        ./configure $PLATFORM "$MINOR_GEMS_PATH" --discord_sdk_path "${DISCORD_SDK_PATH}"
    else
        ./configure $PLATFORM
    fi
    if [[ $PLATFORM == 5 ]]; then export PATH="/usr/i686-w64-mingw32/bin:${PATH}"; fi
}

configure_server(){
    cd $ONE_LIFE_SERVER
    ./configure $PLATFORM
}
configure_editor(){
    cd $ONE_LIFE
    ./configure $PLATFORM
    if [[ $PLATFORM == 5 ]]; then export PATH="/usr/i686-w64-mingw32/bin:${PATH}"; fi
}

cp_game(){
    if [[ $PLATFORM == 5 ]]; then
        rm -f OneLife.exe
        cp $GAME_SOURSE/OneLife.exe $OUTPUT
        #rm ../OneLife/gameSource/OneLife.exe # this causes it to wait ~15s without any reason!
    fi
    if [[ $PLATFORM == 1 ]]; then
        mv -f $GAME_SOURSE/OneLife $OUTPUT
    fi
}

cp_server(){
    if [[ $PLATFORM == 5 ]]; then mv $ONE_LIFE_SERVER/OneLifeServer.exe $OUTPUT; fi
    if [[ $PLATFORM == 1 ]]; then mv $ONE_LIFE_SERVER/OneLifeServer $OUTPUT; fi
}

cp_editor(){
    if [[ $PLATFORM == 5 ]]; then cp -f $GAME_SOURSE/EditOneLife.exe $OUTPUT; fi
    if [[ $PLATFORM == 1 ]]; then cp -f $GAME_SOURSE/EditOneLife $OUTPUT; fi
}

cp_game_version_number(){
    if [ -f $OUTPUT/dataVersionNumber.txt ];then
        rm $OUTPUT/dataVersionNumber.txt
    fi
    cp $ONE_LIFE_DATA/dataVersionNumber.txt $OUTPUT
}

cp_sdl_win(){
    if [[ $PLATFORM == 5 ]] && [ ! -f SDL.dll ]; then cp $ONE_LIFE/build/win32/SDL.dll $OUTPUT; fi
}

cp_clearCache_win(){
    if [[ $PLATFORM == 5 ]] && [ ! -f clearCache.bat ]; then cp $ONE_LIFE/build/win32/clearCache.bat $OUTPUT; fi
}

cp_discord_sdk(){
    if [ -d $DISCORD_SDK_PATH ]; then
        if [[ $PLATFORM == 5 ]]; then cp $DISCORD_SDK_PATH/lib/x86/discord_game_sdk.dll $OUTPUT; fi
        if [[ $PLATFORM == 1 ]]; then
            if [[ ! -f $OUTPUT/discord_game_sdk.so ]]; then
                sudo cp $DISCORD_SDK_PATH/lib/x86_64/discord_game_sdk.so $OUTPUT
                sudo chmod a+r $OUTPUT/discord_game_sdk.so
            fi
        fi
    fi
}

set -e
main "$@"
