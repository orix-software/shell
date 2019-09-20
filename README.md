[![Build Status](https://travis-ci.org/orix-software/shell.svg?branch=master)](https://travis-ci.org/orix-software/shell)

Maintainers :

* Jede
* Assinie 

# Rules for source code

* Macro are in uppercase
* use userzp label to get space from zerp page. You can have at least 10 bytes from userzp in order to use zp
* Allocate with malloc your memory. In that case, in the future, it will be easier to start multithreading.
* userzp will be managed by kernel when multithreading occurs


# Shell for Orix (ROM)


How to compile ?

You need to download cc65 lastest version in order to get last telestrat.inc file.

## How to install ?
you need to put this bank in bank 5

## How a binary is started ?
* if the command is ./Mycommand, orix tries to start command from current path
if not :
* Orix tries to see if the command is in ROM banks, if it's the case, the command is launched
* If the command is not in any banks, it tries to start binary from bin/ folder
* if it's not the in binary folder, it prints command not found

## Build options

### Root file on sdcard 
Pass to ca65 command line : -DWITH_SDCARD_FOR_ROOT=1
or else it will reads en usb key
