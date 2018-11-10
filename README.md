[![Build Status](https://travis-ci.org/orix-software/shell.svg?branch=master)](https://travis-ci.org/orix-software/shell)

# Shell for Orix (ROM)

How to compile ?

You need to download cc65 lastest version in order to get last telestrat.inc file.

# How to install ?
you need to put this bank in bank 5

# How a binary is started ?
* if the command is ./Mycommand, orix tries to start command from current path
if not :
* Orix tries to see if the command is in ROM banks, if it's the case, the command is launched
* If the command is not in any banks, it tries to start binary from bin/ folder
* if it's not the in binary folder, it prints command not found