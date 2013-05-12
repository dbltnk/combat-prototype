@ECHO OFF
md buildtmp
copy localconfig.lua.dist "%~dp0\buildtmp\localconfig.lua"
copy readme.md "%~dp0\buildtmp\readme.txt"
winrar a -r -x*\server -x*\build_material -x*\buildtmp -x@"%~dp0\build_material\buildexclude.txt" "%~dp0\buildtmp\game.zip"
copy "%~dp0\buildtmp\game.zip" "%~dp0\buildtmp\game.love"
del "%~dp0\buildtmp\game.zip"
copy "%~dp0\build_material\lovemacosx\love.app" "%~dp0\buildtmp\love.app" ::cannot copy .app
::copy /b %~dp0\buildtmp\game.love" "%~dp0\buildtmp\love.app\Contents\Ressources\"
::del "%~dp0\buildtmp\game.love"
:: modify plist http://love2d.org/wiki/Game_Distribution
::winrar a -ep1 dastal_proto1_macosx.zip buildtmp\*
::rd /s /q buildtmp
pause
