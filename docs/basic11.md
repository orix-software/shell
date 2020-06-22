# Command: basic11

### Start Atmos rom

## SYNOPSYS
+ basic11

## DESCRIPTION
This command starts the atmos rom (available in bank 6), but this rom is special because it did not test RAM. Cload and csave command calls CH376 routines. It means that it calls file from sdcard.

Cload works with .tap file. Multitap files works

Get a tape file, and place it in the root folder of the usbkey. Starts "basic11"

CLOAD"ZORGONS => it will load zorgons.tap

## Working software
+ all games except the Hobbit (another ROM is available)

## SOURCE
https://github.com/orix-software/shell/blob/master/src/commands/basic11.asm
