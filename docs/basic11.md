# Command: basic11

### Start Atmos rom

## SYNOPSYS
+ basic11

## DESCRIPTION
This command starts the atmos rom (available in bank 6), but this rom is special because it did not test RAM. Cload and csave command calls CH376 routines. It means that it calls file from sdcard.

Cload works with .tap file. if there is many tape file in a tape file, cload will load only the first tape file.

Get a tape file, and place it in the root folder of the usbkey. Starts "basic11"

CLOAD"ZORGONS => it will load zorgons.tap

## Working software
+ Super jeep, swiv, Trex, Zorgons

## SOURCE
https://github.com/orix-software/shell/blob/master/src/commands/basic11.asm
