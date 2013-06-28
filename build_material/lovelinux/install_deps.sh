#!/bin/bash

pushd `dirname $0` > /dev/null
D=`pwd -P`
popd > /dev/null

cd "$D"

echo install dependencies

sudo apt-get install libenet1a love luarocks

echo install lua enet

sudo luarocks install enet

echo reset config

mkdir -p ~/.local/share/love/combat-prototype/
cd ~/.local/share/love/combat-prototype/
ln -s "$D/localconfig.lua"
cp "$D/localconfig.lua.dist" "$D/localconfig.lua"

echo "your local config: $D/localconfig.lua" 
