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
ifneq ($(TRAVIS_BRANCH), master)
RELEASE=alpha
else
RELEASE:=$(shell cat VERSION)
endif
endif

TELESTRAT_TARGET_RELEASE=release/telestrat
MYDATE = $(shell date +"%Y-%m-%d %H:%m")

ifdef $(TRAVIS_BRANCH)
ifneq ($(TRAVIS_BRANCH), master)
RELEASE=alpha
endif
else
RELEASE:=$(shell cat VERSION)
endif

build: $(SOURCE)
	@date +'.define __DATE__ "%F %R"' > src/build.inc
	$(AS) $(CFLAGS) $(SOURCE) -o $(ROM).ld65 --debug-info
	$(LD) -vm -m map7banks.txt -Ln memorymap.txt  -tnone $(ROM).ld65 -o $(ROM).rom
	$(AS) $(CFLAGS) $(SOURCE) -DWITH_SDCARD_FOR_ROOT=1 -o $(ROM)sd.ld65 --debug-info
	$(LD) -vm -m map7banks.txt -DWITH_SDCARD_FOR_ROOT=1 -DWITH_TWILIGHTE_BOARD=1 -Ln memorymap.txt  -tnone $(ROM)sd.ld65 -o $(ROM)sd.rom

test:
	#cp src/include/orix.h build/usr/include/orix/
	mkdir -p build/usr/src/shell/src/
	mkdir -p build/usr/share/man/
	mkdir -p build/usr/share/fonts/
	mkdir -p build/usr/share/shell/
	cp data/USR/SHARE/FONTS/* build/usr/share/fonts/ -adpR
	cp $(ROM)sd.rom build/usr/share/shell/
	sh tools/builddocs.sh
	cp Makefile build/usr/src/shell/
	cp README.md build/usr/src/shell/
	cp src/* build/usr/src/shell/src/ -adpR
	#cp data/* build/ -adpR
	#cp README.md build/usr/share/doc/$(ORIX_ROM)/
	#ls -l $(HOMEDIR)
	export ORIX_PATH=`pwd`
	cd build && tar -c * > ../$(ORIX_ROM).tar &&	cd ..
	filepack  $(ORIX_ROM).tar $(ORIX_ROM).pkg
	gzip $(ORIX_ROM).tar
	mv $(ORIX_ROM).tar.gz $(ORIX_ROM).tgz
	php buildTestAndRelease/publish/publish2repo.php $(ORIX_ROM).tgz ${hash} 6502 tgz $(RELEASE)

  
  


  

