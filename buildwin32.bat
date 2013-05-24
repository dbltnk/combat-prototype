@ECHO OFF
md buildtmp
copy localconfig.lua.dist "%~dp0\buildtmp\localconfig.lua"
copy readme.md "%~dp0\buildtmp\readme.txt"
"C:\Program Files\WinRAR\WinRAR.exe" a -r -x*\server -x*\build_material -x*\buildtmp -x@"%~dp0\build_material\buildexclude.txt" "%~dp0\buildtmp\game.zip"
copy "%~dp0\buildtmp\game.zip" "%~dp0\buildtmp\game.love"
del "%~dp0\buildtmp\game.zip"
copy "%~dp0\build_material\lovewin32\*.*" "%~dp0\buildtmp\"
copy /b "%~dp0\buildtmp\love.exe"+"%~dp0\buildtmp\game.love" "%~dp0\buildtmp\dastal_proto1.exe"
del "%~dp0\buildtmp\game.love"
del "%~dp0\buildtmp\love.exe"
"C:\Program Files\WinRAR\WinRAR.exe" a -ep1 dastal_proto1_win32.zip buildtmp\*
rd /s /q buildtmp
pause


