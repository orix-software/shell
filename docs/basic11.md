# basic11

## Introduction

Start Atmos rom

## SYNOPSYS

+ basic11
+ basic11 -g
+ basic11 -l
+ basic11 "MYTAPE

## DESCRIPTION

This command starts the atmos rom. This rom did not test RAM and cload/csave are done on sdcard. It means that it calls file from sdcard.

Cload works with .tap file. Multitap files works too.

Get a tape file, and place it in the root folder of the sdcard.

Starts basic11 :
/#basic11
or
/#basic11 "DEFENDER"

CLOAD"ZORGONS => it will load zorgons.tap

## Working software

+ Some games are not working because the rom in order to have the software working is release yet

## SOURCE

https://github.com/orix-software/shell/blob/master/src/commands/basic11.asm
