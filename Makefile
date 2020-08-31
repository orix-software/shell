AS=ca65
CC=cl65
LD=ld65
CFLAGS=-ttelestrat
LDFILES=
ROM=shell
ORIX_ROM=shell

all : build
.PHONY : all

HOMEDIR=/home/travis/bin/
HOMEDIR_ORIX=/home/travis/build/orix-software/$(ROM)/
ORIX_VERSION=1.0

SOURCE=src/$(ROM).asm



ifdef TRAVIS_BRANCH
ifeq ($(TRAVIS_BRANCH), master)
RELEASE:=$(shell cat VERSION)
else
RELEASE:=alpha
endif

endif




TELESTRAT_TARGET_RELEASE=release/telestrat
MYDATE = $(shell date +"%Y-%m-%d %H:%m")


build: $(SOURCE)
	@date +'.define __DATE__ "%F %R"' > src/build.inc
	$(AS) $(CFLAGS) $(SOURCE) -o $(ROM).ld65 --debug-info
	$(LD) -vm -m map7banks.txt -Ln memorymap.txt  -tnone $(ROM).ld65 -o $(ROM).rom
	$(AS) $(CFLAGS) $(SOURCE) -DWITH_SDCARD_FOR_ROOT=1 -o $(ROM)sd.ld65 --debug-info
	$(LD) -vm -m map7banks.txt -DWITH_SDCARD_FOR_ROOT=1 -DWITH_TWILIGHTE_BOARD=1 -Ln memorymap.txt  -tnone $(ROM)sd.ld65 -o $(ROM)sd.rom

test:
	#cp src/include/orix.h build/usr/include/orix/



  

