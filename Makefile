AS=ca65
CC=cl65
LD=ld65
CFLAGS=-ttelestrat
LDFILES=
ROM=shell

all : init build after_success docs
.PHONY : all

SOURCE=src/$(ROM).asm

ifeq ($(CC65_HOME),)
        CC = cl65
        AS = ca65
        LD = ld65
        AR = ar65
else
        CC = $(CC65_HOME)/bin/cl65
        AS = $(CC65_HOME)/bin/ca65
        LD = $(CC65_HOME)/bin/ld65
        AR = $(CC65_HOME)/bin/ar65
endif

init:
	./configure

build: $(SOURCE)
	echo Build Kernel for Twilighte board
	@date +'.define __DATE__ "%F %R"' > src/build.inc
	$(AS) $(CFLAGS) $(SOURCE) -DWITH_TWILIGHTE_BOARD=1 -o $(ROM).ld65 --debug-info
	$(LD) -vm -m map7banks.txt -Ln memorymap.txt  -tnone $(ROM).ld65 -o $(ROM).rom libs/lib8/twil.lib libs/lib8/ch376.lib
	cp $(ROM).rom $(ROM)us.rom
	$(AS) $(CFLAGS) $(SOURCE) -DWITH_SDCARD_FOR_ROOT=1 -o $(ROM)sd.ld65 --debug-info
	$(LD) -vm -m map7banks.txt -DWITH_SDCARD_FOR_ROOT=1 -DWITH_TWILIGHTE_BOARD=1 -Ln memorymap.txt  -tnone $(ROM)sd.ld65 -o $(ROM)sd.rom libs/lib8/twil.lib libs/lib8/ch376.lib
	echo Build Kernel for Telestrat
	$(AS) $(CFLAGS) $(SOURCE)  -o $(ROM).ld65 --debug-info
	$(LD) -vm -m map7banks.txt -Ln memorymap.txt  -tnone $(ROM).ld65 -o $(ROM)t.rom libs/lib8/twil.lib libs/lib8/ch376.lib
	cp $(ROM)t.rom $(ROM)tus.rom
	$(AS) $(CFLAGS) $(SOURCE) -DWITH_SDCARD_FOR_ROOT=1 -o $(ROM)sd.ld65 --debug-info
	$(LD) -vm -m map7banks.txt -DWITH_SDCARD_FOR_ROOT=1 -DWITH_TWILIGHTE_BOARD=1 -Ln memorymap.txt  -tnone $(ROM)sd.ld65 -o $(ROM)tsd.rom libs/lib8/twil.lib libs/lib8/ch376.lib

docs:
	sh tools/builddocs.sh

after_success:
	ls -l
	ls -l ../
	mkdir -p build/usr/src/shell/src/
	mkdir -p build/usr/share/man/
	mkdir -p build/usr/share/fonts/
	mkdir -p build/usr/share/shell/
	cp data/USR/SHARE/FONTS/* build/usr/share/fonts/ -adpR
	cp shellsd.rom build/usr/share/shell/
	cp shellus.rom build/usr/share/shell/

	cp Makefile build/usr/src/shell/
	cp README.md build/usr/src/shell/
	cp src/* build/usr/src/shell/src/ -adpR


