#!/bin/bash
cd "$(dirname "${0}")/.."
compile_root=$(pwd)
output=$compile_root/output
one_life=$compile_root/OneLife
one_life_data=$compile_root/OneLifeData7
one_life_server=$one_life/server
game_source=$one_life/gameSource
mini_one_life_compile=$compile_root/miniOneLifeCompile

discord_sdk_path="$compile_root/dependencies/discord_game_sdk"
minor_gems_path="$compile_root/minorGems"

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
                export compile=$OPTARG;;
            p)
                export platform=$OPTARG;;
            \?)
                echo "Error: Invalid option"
                exit;;
        esac
    done
}

check_input(){
    if [ -z "$compile" ]; then
        echo "Error: Compile option wasn't satisfied"
        exit
    elif ! [ "$compile" -ge 1 ] || ! [ "$compile" -le 7 ];then
        echo "Error: Compile option is beyond valid range 1 to 7"
        exit
    fi

    if [ -z "$platform" ]; then
        platform=1
        echo "Warning: Platform option wasn't satisfied. It was set to 1(Linux)."
    elif ! [ "$platform" -eq 1 ] && ! [ "$platform" -eq 5 ]; then
        echo "Error: Platform option is valid only for 1 and 5"
        exit
    fi
}

compiler_switch(){
    if (( ($compile & 1) != 0 )); then
        echo "Compiling client ..."
        compile_client
    fi
    if (( ($compile & 2) != 0 )); then
        echo "Compiling server ..."
        compile_server
    fi
    if (( ($compile & 4) != 0 )); then
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
    cp $one_life/{gameSource/reverbImpulseResponse.aiff,server/wordList.txt} $output
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

    cp $one_life_server/{firstNames.txt,lastNames.txt,wordList.txt} $output
    cp_game_version_number
    cp_server
}

compile_editor(){
    configure_editor

    make_editor
    make_output_dir
    make_editor_symLinks
    make_game_settings

    cp $game_source/{us_english_60.txt,reverbImpulseResponse.aiff} $output
    cp_game_version_number
    cp_sdl_win
    cp_editor
}

make_output_dir(){
    if ! [ -d $output ];then
        mkdir $output
    fi
}

make_game_settings(){
    if ! [ -d "$output/settings" ];then
        cp -r $game_source/settings $output/settings
    fi
}

make_client_symLinks(){
    make_main_data_symLinks
    make_secondary_data_symLinks
}

make_server_symLinks(){
    if ! [ -d $output/tutorialMaps ];then
        TARGET="$output"
        FOLDERS="objects transitions categories tutorialMaps"
        LINK="$one_life_data"
        $mini_one_life_compile/util/createSymLinks.sh $platform "$FOLDERS" $TARGET $LINK
    fi
}

make_editor_symLinks(){
    make_main_data_symLinks
    make_secondary_data_symLinks
}

make_main_data_symLinks(){
    if ! [ -d $output/animations ];then
        TARGET="$output"
        FOLDERS="animations categories ground music objects sounds sprites transitions"
        LINK="$one_life_data"
        $mini_one_life_compile/util/createSymLinks.sh $platform "$FOLDERS" $TARGET $LINK
    fi
}

make_secondary_data_symLinks(){
    if ! [ -d $output/graphics ];then
        TARGET="$output"
        FOLDERS="graphics otherSounds languages"
        LINK="$game_source"
        $mini_one_life_compile/util/createSymLinks.sh $platform "$FOLDERS" $TARGET $LINK
    fi
}


make_client(){
    cd $game_source
    make
}

make_server(){
    cd $one_life_server
    make
}

make_editor(){
    cd gameSource
    ./makeEditor.sh
}

configure_client(){
    cd $one_life
    if [ -d $discord_sdk_path ]; then
        ./configure $platform "$minor_gems_path" --discord_sdk_path "${discord_sdk_path}"
    else
        ./configure $platform
    fi
    if [[ $platform == 5 ]]; then export PATH="/usr/i686-w64-mingw32/bin:${PATH}"; fi
}

configure_server(){
    cd $one_life_server
    ./configure $platform
}
configure_editor(){
    cd $one_life
    ./configure $platform
    if [[ $platform == 5 ]]; then export PATH="/usr/i686-w64-mingw32/bin:${PATH}"; fi
}

cp_game(){
    if [[ $platform == 5 ]]; then
        rm -f OneLife.exe
        cp $game_source/OneLife.exe $output
        #rm ../OneLife/gameSource/OneLife.exe # this causes it to wait ~15s without any reason!
    fi
    if [[ $platform == 1 ]]; then
        mv -f $game_source/OneLife $output
    fi
}

cp_server(){
    if [[ $platform == 5 ]]; then mv $one_life_server/OneLifeServer.exe $output; fi
    if [[ $platform == 1 ]]; then mv $one_life_server/OneLifeServer $output; fi
}

cp_editor(){
    if [[ $platform == 5 ]]; then cp -f $game_source/EditOneLife.exe $output; fi
    if [[ $platform == 1 ]]; then cp -f $game_source/EditOneLife $output; fi
}

cp_game_version_number(){
    if [ -f $output/dataVersionNumber.txt ];then
        rm $output/dataVersionNumber.txt
    fi
    cp $one_life_data/dataVersionNumber.txt $output
}

cp_sdl_win(){
    if [[ $platform == 5 ]] && [ ! -f SDL.dll ]; then cp $one_life/build/win32/SDL.dll $output; fi
}

cp_clearCache_win(){
    if [[ $platform == 5 ]] && [ ! -f clearCache.bat ]; then cp $one_life/build/win32/clearCache.bat $output; fi
}

cp_discord_sdk(){
    if [ -d $discord_sdk_path ]; then
        if [[ $platform == 5 ]]; then cp $discord_sdk_path/lib/x86/discord_game_sdk.dll $output; fi
        if [[ $platform == 1 ]]; then
            if [[ ! -f $output/discord_game_sdk.so ]]; then
                sudo cp $discord_sdk_path/lib/x86_64/discord_game_sdk.so $output
                sudo chmod a+r $output/discord_game_sdk.so
            fi
        fi
    fi
}

set -e
main "$@"
