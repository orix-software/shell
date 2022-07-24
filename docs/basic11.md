# basic11

## Introduction

Start Atmos rom. You can type basic11 or press FUNCT+B to start.

Load a personal .tap file
When you starts basic11 commands, the default path is « /home/basic11/ ». Each action on the basic11 mode will be done in
this folder (cload/csave). If you cload a tape file, it must be in « /home/basic11 » folder.

You have downloaded a .tap file, and want to use it. Then, you can create a
folder /home/basic11/
Under Orix
/#mkdir home
/#cd home
/home#mkdir basic11
/home#cd basic11
Put you file in this folder from your PC, and start basic11 (you don’t need to be in the «/home/basic11 » folder to start
basic11 with no parameter. By default, basic11 starts in « /home/basic11/ »
Oric.org tape file
When you downloaded sdcard.tgz and unzip it into sdcard or usbkey device, there is many tape file included in this archive.
You don’t need to move these type file, if you know the key, you can starts it from commands line. In this case, it will load
the correct basic1.1 rom to start the tape file (see below), and the correct joystick configuration if it’s correct.
Oric.org tape file update
Each week a new software.tgz is generated. You can download it from « repo » and unzip it on the device. It will generate
last tape file and last joysticks configuration.
Search a tape file from command line

Basic11 has also many.tap files inserted in sdcard.tgz
8
Try to find the software with option -l
/# basic11 -l
If you find your software, you can do perform ctrl+c.
You can type space to do a pause.
On that case, you can launch the tape file like :
/# basic11 «KEYDISPLAYED
When KEYDISPLAYED is the key displayed in key column. Please note that the key must be in UPPERCASE
Load a tap file from command line
Note that MYFILE must be in UPPERCASE
/# basic11 «MYFILE
If MYFILE is in the oric.org database, it will launch the software with the filename MYFILE.
If basic11 command does not find MYFILE in the oric.org database, it will try to load it from /home/basic11/ folder.
Save your program
If you start « basic11 » with no options, basic rom will starts and each csave (or cload) actions will store files in « /home/basic11 »
folder

## Start basic11 menu

If you type « basic11 -g » on command line or FUNCT+G, you will have a
menu with all software which have a download link on oric.org (only atmos version and when a tape file is available).
/#basic11 -g
You can use left and right letters to change to a new letter. If the letter is empty, it means that there is no available tap file
for this letter.
You can use up and down link to navigate into software. If you press enter, the software will starts.
Note that not all games are working yet. Some times, chars are corrupted. If the joysticks does not works, there is two case :
• the game does not call rom routine to manage keyboard
• keyboard mapping is not done yet
You can use arrows to navigate into the menu :
• up and down to select the software
• right and left to switch to the menu letters
Some letters are empty. It means that there is no software with tape file available on oric.org for this letter
Quit basic11
If you want to quit basic11 from interpreter command line, you can type « QUIT ». This will force to reboot to Orix (you can
also use reset button)

## How the .tap file starts
If you only type « basic11 », this will start bank 6 (normal basic rom). The default folder in that case is «/home/basic11 »
If you type « basic11 » with a tape file as an argument, there is 2 cases
1. The tape file (key) is already known in oric.org website, then basic11 try to find it in its databank file (/var/cache/basic11/
folder). If the key is found, it will start the tape file located in «/usr/share/basic11/... »
2. If the key is unknown, it will try to find it in «/home/basic11 »
If the tap file is in the oric.org db file, basic11 will load the software configuration from the db software file (as joystick
configuration, and the id of the rom). Basic11 load the right rom into ram bank, override the default basic11 path to the tape
file folder (« usr/share/basic11/[firstletter software].
It means that if you load this kind of software and you can quit the software, each file action in basic11 rom, will be performed
in « usr/share/basic11/[firstletter software]. »
Not working tapes (for instance)
• All Oric-1 games can be started with FUNCT+L in ROM menu : start oric-1 (depending of your device), and put .tap
files in /home/basic10
• Software which does not work (25), but the number can be reduced in future release.
cobra Cobra pinball Damsel in distress
Rush hour 4K
Le diamant de l’ile maudite Durendal HU*BERT
Hunchback Schtroumpfs Stanley (ROM 0,1 tested)
Them Titan Visif
Xenon III Dig Dog Elektro Storm
Kilburn Encounter Le tresor du pirate L’aigle d’or (ROM 0,1 tested)
Compatible (micropuce) Volcanic demo Clavidact
DAO Cobra Soft CW-Morse The Hellion
MARC Caspak Kryllis : when we lost one life, the game does not restar

# Tape with altered charset

Fire flash Scuba Dive 3D fongus (i,f letters)
Joysticks issues
We did keyboard/joystick mapping for a lot of games, but we did not set the keyboard mapping for all software. If you want
to help us, contact us.
Some game does not work because they handle their own keyboard routine. It could be handle with hardware tricks but, it’s
not done.
Some others games uses special keys (SHIFT, CTRL) for direction or the first button. Theses cases are not handle yet : but it
could in the future.


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
