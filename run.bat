@echo off

SET ORICUTRON="..\..\..\oricutron-iss\"

SET RELEASE="30"
SET UNITTEST="NO"

SET ORIGIN_PATH=%CD%

SET ROM=monitor

%CC65%\ca65.exe -ttelestrat --include-dir %CC65%\asminc\ src/%ROM%.asm -o %ROM%.ld65
%CC65%\ld65.exe -tnone  %ROM%.ld65 -o %ROM%.rom



IF "%1"=="NORUN" GOTO End

copy %ROM%.rom %ORICUTRON%\roms\monitor.rom > NUL

cd %ORICUTRON%
oricutron -mt  --symbols "%ORIGIN_PATH%\xa_labels_orix.txt"

:End
cd %ORIGIN_PATH%
%OSDK%\bin\MemMap "%ORIGIN_PATH%\xa_labels_orix.txt" memmap.html O docs/telemon.css

