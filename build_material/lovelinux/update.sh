#!/bin/bash

pushd `dirname $0` > /dev/null
D=`pwd -P`
popd > /dev/null

rsync -avzr buffy.leenox.de::dastal/linux/. .
