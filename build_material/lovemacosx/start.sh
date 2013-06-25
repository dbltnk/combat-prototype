#!/bin/bash

pushd "`dirname $0`" > /dev/null
D="`pwd -P`"
popd > /dev/null

echo $D
cd "$D"
open "$D/love.app" --args "$D/combat-prototype"
