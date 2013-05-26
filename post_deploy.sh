#!/bin/bash

echo update server
cd server
npm install
cd ..

echo changelog
echo -n `git log --pretty=oneline|wc -l` > changelog.txt
echo " commits" >> changelog.txt
echo "------------" >> changelog.txt
git log --pretty=oneline --abbrev-commit --since "2 weeks" >> changelog.txt

echo build client win
rm -rf buildtmp
mkdir buildtmp
cp localconfig.lua.dist buildtmp
cp README.md buildtmp/readme.txt
zip -r buildtmp.zip . -x@build_material/buildexclude.txt -x server\* -x build_material\* -x buildtmp\* -x .git\* -x build\*
mv buildtmp.zip buildtmp/game.love
cp build_material/lovewin32/* buildtmp
cat buildtmp/love.exe buildtmp/game.love > buildtmp/dastal_proto1.exe
rm buildtmp/game.love
rm buildtmp/love.exe
cp changelog.txt buildtmp
mv buildtmp dastal_proto1
zip -r dastal_proto1.zip dastal_proto1
mkdir -p build
rm -rf build/dastal_proto1
mv dastal_proto1 build
mv dastal_proto1.zip build
rm -rf buildtmp

