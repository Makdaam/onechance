#!/bin/bash

cd onechance
rm ../onechance.zip
zip -r ../onechance.zip *
cd ..
mv onechance.zip onechance.love
cp onechance.love distro/onechance_linux.love

cat windows_raw/love.exe onechance.love > distro/windows/onechance.exe
cd distro
rm onechance_windows.zip
zip -r onechance_windows.zip windows/*

