#! /bin/bash
HOMEDIR=build/
HOMEDIRDOC=docs/
mkdir build/usr/share/man -p
mkdir -p ../build/usr/share/man/ 
LIST_COMMAND='bank basic10 basic11 cat cd clear cp echo env help ioports lscpu ls meminfo monitor lsmem mkdir man mount mv orix otimer ps pwd reboot pwd rm setfont sh touch twil uname viewhrs'
echo Generate hlp
for I in $LIST_COMMAND; do
echo Generate $I
cat $HOMEDIRDOC/$I.md | ../md2hlp/src/md2hlp.py3 -c $HOMEDIRDOC/md2hlp.cfg > build/usr/share/man/$I.hlp
done 
