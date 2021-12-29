@echo off

rem SET ORICUTRON="D:\Onedrive\oric\oricutron-iss2-debug\"

rem SET ORICUTRON="D:\Onedrive\oric\oricutron_twilighte"

rem @SET ORICUTRON="D:\Onedrive\oric\projets\oric_software\oricutron_jedeoric\msvc\VS2019\x64\Release\"
SET ORICUTRON="D:\Users\plifp\Onedrive\oric\oricutron_twilighte"

SET RELEASE="30"
SET UNITTEST="NO"

SET ORIGIN_PATH=%CD%

SET ROM=shell
rem -DWITH_SDCARD_FOR_ROOT=1 
rem 
%CC65%\ca65.exe -DWITH_SDCARD_FOR_ROOT=1 -DWITH_TWILIGHTE_BOARD=1 -DTWILIGHTE_BOARD_LINEAR_BANK=1 -ttelestrat --include-dir %CC65%\asminc\ src/%ROM%.asm -o %ROM%.ld65  
%CC65%\ld65.exe -DWITH_SDCARD_FOR_ROOT=1 -DWITH_TWILIGHTE_BOARD=1 -tnone  %ROM%.ld65 -o %ROM%.rom  -Ln shell.sym libs/lib8/twil.lib libs/lib8/ch376.lib

%CC65%\ca65.exe -DWITH_SDCARD_FOR_ROOT=1 -DWITH_TWILIGHTE_BOARD=1  -ttelestrat --include-dir %CC65%\asminc\ src/shellext.asm -o shellext.ld65  
%CC65%\ld65.exe -DWITH_SDCARD_FOR_ROOT=1 -DWITH_TWILIGHTE_BOARD=1 -tnone  shellext.ld65 -o shellext.rom  -Ln shellext.sym 



IF "%1"=="NORUN" GOTO End

copy %ROM%.rom %ORICUTRON%\roms\ > NUL
copy shellext.rom  %ORICUTRON%\roms\ > NUL
copy myprojectbp.txt %ORICUTRON%

cd %ORICUTRON%
oricutron -r :myprojectbp.txt
:End
cd %ORIGIN_PATH%
%OSDK%\bin\MemMap "%ORIGIN_PATH%\xa_labels_orix.txt" memmap.html O docs/shell.css

