#!/bin/bash

pushd `dirname $0` > /dev/null
D=`pwd -P`
popd > /dev/null

cd "$D/combat-prototype"

love .
