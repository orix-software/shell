# Command: basic11

### Start Atmos rom

## SYNOPSYS
+ basic11

## DESCRIPTION
This command starts the atmos rom. This rom did not test RAM and cload/csave or done on sdcard. It means that it calls file from sdcard.

Cload works with .tap file. Multitap files works too.

Get a tape file, and place it in the root folder of the sdcard. 

Starts basic11 :
/#basic11
or
/#basic 11 "DEFENDER"

CLOAD"ZORGONS => it will load zorgons.tap

## Working software
+ all games except the Hobbit (another ROM is available)

## SOURCE
https://github.com/orix-software/shell/blob/master/src/commands/basic11.asm
