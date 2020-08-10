@echo off

SET ORICUTRON="..\..\..\..\oricutron-iss2-debug\"

SET RELEASE="30"
SET UNITTEST="NO"

SET ORIGIN_PATH=%CD%

SET ROM=shell
rem -DWITH_SDCARD_FOR_ROOT=1 
rem 
%CC65%\ca65.exe -DWITH_SDCARD_FOR_ROOT=1 -DWITH_TWILIGHTE_BOARD=1 -ttelestrat --include-dir %CC65%\asminc\ src/%ROM%.asm -o %ROM%.ld65  
%CC65%\ld65.exe -DWITH_SDCARD_FOR_ROOT=1 -DWITH_TWILIGHTE_BOARD=1 -tnone  %ROM%.ld65 -o %ROM%.rom  -Ln shell.sym



IF "%1"=="NORUN" GOTO End

copy %ROM%.rom %ORICUTRON%\roms\ > NUL

rem xcopy data\*.* %ORICUTRON%\sdcard\ > NUL

cd %ORICUTRON%
oricutron -mt  --symbols "%ORIGIN_PATH%\xa_labels_orix.txt" -r :bp.txt

:End
cd %ORIGIN_PATH%
%OSDK%\bin\MemMap "%ORIGIN_PATH%\xa_labels_orix.txt" memmap.html O docs/telemon.css

