# basic10

## Introduction

Start Oric-1 rom

## SYNOPSYS

+ basic10
+ basic10 -g
+ basic10 -l
+ basic10 "MYTAPE

## DESCRIPTION

This command starts the Oric-1 rom. This rom did not test RAM and cload/csave are done on sdcard. It means that it calls file from sdcard.

Cload works with .tap file. Multitap files works too.

Get a tape file, and place it in the root folder of the sdcard.

When there is no parameter, basic10 has /home/basic10 default folder

Starts basic10 :
/#basic10
or
/#basic10 "DEFENDER

CLOAD"ZORGONS => it will load zorgons.tap

## Working software

+ all games except the Hobbit (another ROM is available)

## SOURCE

https://github.com/orix-software/shell/blob/master/src/commands/basic10.asm
