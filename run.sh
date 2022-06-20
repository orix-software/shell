# export DISPLAY=172.17.160.1:0
ORICUTRON_PATH="/mnt/c/Users/plifp/OneDrive/oric/oricutron_wsl/oricutron"



LD65_LIB=/usr/share/cc65/lib/
export LD65_LIB

ca65 -DWITH_SDCARD_FOR_ROOT=1 -DWITH_TWILIGHTE_BOARD=1 -DTWILIGHTE_BOARD_LINEAR_BANK=1 -ttelestrat src/shell.asm -o shell.ld65
ld65 -DWITH_SDCARD_FOR_ROOT=1 -DWITH_TWILIGHTE_BOARD=1 -tnone  shell.ld65 -o shell.rom  -Ln shell.sym libs/lib8/twil.lib libs/lib8/ch376.lib

# ca65 -DWITH_SDCARD_FOR_ROOT=1 -DWITH_TWILIGHTE_BOARD=1  -ttelestrat --include-dir %CC65%\asminc\ src/shellext.asm -o shellext.ld65
# ld65 -DWITH_SDCARD_FOR_ROOT=1 -DWITH_TWILIGHTE_BOARD=1 -tnone  shellext.ld65 -o shellext.rom  -Ln shellext.sym



cp shell.rom $ORICUTRON_PATH/roms
cp shellext.rom $ORICUTRON_PATH/roms
cd $ORICUTRON_PATH
./oricutron
cd -

