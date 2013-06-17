#!/bin/bash

cd "`dirname "$0"`"

mkdir -p "/Users/$USER/Library/Application Support/LOVE"
cp enet.so "/Users/$USER/Library/Application Support/LOVE"

if [[ -e "/Users/$USER/Library/Application Support/LOVE/combat-prototype.love/localconfig.lua" ]]
then
    echo there is aready a config
else
    echo creating new config
    mkdir -p "/Users/$USER/Library/Application Support/LOVE/combat-prototype.love"
    cp localconfig.lua.dist "/Users/$USER/Library/Application Support/LOVE/combat-prototype.love/localconfig.lua" 
fi

ln -s "/Users/$USER/Library/Application Support/LOVE/combat-prototype.love/localconfig.lua"

open -e "/Users/$USER/Library/Application Support/LOVE/combat-prototype.love/localconfig.lua" 

