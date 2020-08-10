#! /bin/bash
HOMEDIR=build/
HOMEDIRDOC=docs/
HOMEDIR_ORIX=/home/travis/build/oric-software/orix
mkdir -p ../build/usr/share/man/ 
LIST_COMMAND='bank basic11 cat cd clear cp date echo env help ioports lscpu ls meminfo monitor lsmem mkdir man mount mv orix ps pwd reboot pwd rm setfont touch twil uname viewhrs'
echo Generate hlp
for I in $LIST_COMMAND; do
echo Generate $I
cat $HOMEDIRDOC/$I.md | md2hlp.py -c $HOMEDIRDOC/md2hlp.cfg > build/usr/share/man/$I.hlp
done 
