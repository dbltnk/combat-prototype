#!/bin/bash

cd "`dirname "$0"`"

rsync -avzr buffy.leenox.de::dastal/osx/. .

