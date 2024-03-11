#!/bin/bash
# set -e
cd "$(dirname "${0}")/.."
compile_root=$(pwd)

# Defines what will be the name of the output folder.
output=$compile_root/output_5

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
    echo "Syntax: $0 [OPTION]..."
    echo "options:"
    echo " -h     Print this help and exit."
    echo " -p     Platform 1=Linux, 5=Windows."
    echo " -c     Compiler value is sum of these values."
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
                echo "ERROR Invalid option"
                Help
                exit;;
        esac
    done
}

# Checks input from the user if options are correctly entered.
check_input(){
    if [ -z "$compile" ]; then
        echo "ERROR Compile option wasn't satisfied"
        Help
        exit
    elif [ "$compile" -lt 1 ] || [ "$compile" -gt 7 ];then
        echo "ERROR Compile option is beyond valid range 1 to 7"
        exit
    fi

    if [ -z "$platform" ]; then
        platform=1
        echo "WARNING Platform option wasn't given. Defaulting to 1 (Linux)."
    elif [ "$platform" -ne 1 ] && [ "$platform" -ne 5 ]; then
        echo "ERROR Platform option is valid only for 1 and 5"
        exit
    fi
}

compiler_switch(){
    if (( ($compile & 1) != 0 )); then
	client="yes"
    fi
    if (( ($compile & 2) != 0 )); then
	server="yes"
    fi
    if (( ($compile & 4) != 0 )); then
	editor="yes"
    fi

    compile_here
}

compile_here(){
    configure_here
    test "$client" == "yes" && echo "DEBUG Making client." && cd $game_source && make
    test "$server" == "yes" && echo "DEBUG Making server." && cd $one_life_server && make
    test "$editor" == "yes" && echo "DEBUG Making editor." && cd $game_source && ./makeEditor.sh

    make_output_dir
    make_sym_links
    copy_mv_here
}

make_output_dir(){
    if ! [ -d $output ];then
        echo "DEBUG Creating output directory."
        mkdir $output
    fi
}

cp_game_settings(){
    if ! [ -d "$output/settings" ];then
        cp -vr $game_source/settings $output/settings
    fi
}

make_sym_links(){
    target="$output"

    if [[ "$client" == "yes"  ||  "$editor" == "yes" ]];then
        
        if ! [ -d $output/animations ];then
            echo "DEBUG Making media symLinks."
            link="$one_life_data"
            folders="animations ground music sounds sprites"
            $mini_one_life_compile/util/createSymLinks.sh $platform "$folders" $target $link
        fi
        if ! [ -d $output/graphics ];then
            echo "DEBUG Making main media symLinks."
            link="$game_source"
            folders="graphics otherSounds languages"
            $mini_one_life_compile/util/createSymLinks.sh $platform "$folders" $target $link
        fi
    fi
    if [[ "$server" == "yes" && ! -d "$output/tutorialMaps" ]];then
        echo "DEBUG Making tutorialMaps symLinks."
        link="$one_life_data"
        folders="tutorialMaps"
        $mini_one_life_compile/util/createSymLinks.sh $platform "$folders" $target $link
    fi
    if ! [ -d "$output/objects" ];then
        echo "DEBUG Making definition symLinks."
        link="$one_life_data"
        folders="objects transitions categories"
        $mini_one_life_compile/util/createSymLinks.sh $platform "$folders" $target $link
    fi
}

# Configures make file for specific platforms.
configure_here(){
    if [[ "$client" == "yes" || "$editor" == "yes" ]];then
        echo "DEBUG Configuring make file for client and editor."
        cd $one_life
        if [ -d $discord_sdk_path ];then
            ./configure $platform "$minor_gems_path" --discord_sdk_path "$discord_sdk_path"
        else
            ./configure $platform
        fi
        if [[ $platform -eq 5 ]]; then export PATH="/usr/i686-w64-mingw32/bin:${PATH}"; fi
    fi
    if [ "$server" == "yes" ];then
        echo "DEBUG Configuring make file for server."
        cd $one_life_server
        ./configure $platform
    fi
}

# Copies essential files and moves executable files to output folder.
copy_mv_here(){
    cp_discord_sdk
    cp_game_settings
    cp_game_version_number
    if [ "$client" == "yes" ];then
        cp_clearCache_win
        cp_sdl_win
        cp $one_life/{gameSource/reverbImpulseResponse.aiff,server/wordList.txt} $output
        test "$platform" -eq 5 && mv -vf $game_source/OneLife.exe $output
        test "$platform" -eq 1 && mv -vf $game_source/OneLife $output
    fi
    if [ "$server" == "yes" ];then
    	cp $one_life_server/{firstNames.txt,lastNames.txt,wordList.txt} $output
        test "$platform" -eq 5 && mv -vf $one_life_server/OneLifeServer.exe $output
        test "$platform" -eq 1 && mv -vf $one_life_server/OneLifeServer $output
    fi
    if [ "$editor" == "yes" ];then
        cp_sdl_win
    	cp $game_source/{us_english_60.txt,reverbImpulseResponse.aiff} $output
        test "$platform" -eq 5 && mv -vf $game_source/EditOneLife.exe $output
        test "$platform" -eq 1 && mv -vf $game_source/EditOneLife $output
    fi
    
}

cp_game_version_number(){
    echo "DEBUG Copping dataVersionNumber file."
    cp -vf $one_life_data/dataVersionNumber.txt $output
}

cp_sdl_win(){
    if [[ $platform -eq 5 ]] && [ ! -f SDL.dll ]; then cp $one_life/build/win32/SDL.dll $output; fi
}

cp_clearCache_win(){
    if [[ $platform -eq 5 ]] && [ ! -f clearCache.bat ]; then cp $one_life/build/win32/clearCache.bat $output; fi
}

cp_discord_sdk(){
    echo "DEBUG Copping discord sdk."
    if [ -d $discord_sdk_path ]; then
        test $platform -eq 5 && cp $discord_sdk_path/lib/x86/discord_game_sdk.dll $output
        if [ $platform -eq 1 ] && ! [ -f "$output/discord_game_sdk.so" ] ; then
            # sudo cp $discord_sdk_path/lib/x86_64/discord_game_sdk.so $output
            # sudo chmod a+r $output/discord_game_sdk.so
            cp $discord_sdk_path/lib/x86_64/discord_game_sdk.so $output
        fi
    fi
}

main "$@"
