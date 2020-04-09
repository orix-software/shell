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
	mkdir -p build/usr/src/orix-source-1.0/src/
	mkdir -p build/usr/share/man/
	mkdir -p build/usr/share/fonts/
	mkdir -p build/usr/share/shell/
	cp $(ROM)sd.rom build/usr/share/shell/
	sh tools/builddocs.sh
	cp Makefile build/usr/src/orix-source-1.0/
	cp README.md build/usr/src/orix-source-1.0/
	cp src/* build/usr/src/orix-source-1.0/src/ -adpR
	#cp data/* build/ -adpR
	#cp README.md build/usr/share/doc/$(ORIX_ROM)/
	#ls -l $(HOMEDIR)
	export ORIX_PATH=`pwd`
	cd build && tar -c * > ../$(ORIX_ROM).tar &&	cd ..
	filepack  $(ORIX_ROM).tar $(ORIX_ROM).pkg
	gzip $(ORIX_ROM).tar
	mv $(ORIX_ROM).tar.gz $(ORIX_ROM).tgz
	php buildTestAndRelease/publish/publish2repo.php $(ORIX_ROM).pkg ${hash} 6502 pkg alpha
	php buildTestAndRelease/publish/publish2repo.php $(ORIX_ROM).tgz ${hash} 6502 tgz alpha
	php buildTestAndRelease/publish/publish2repo.php $(ORIX_ROM).pkg ${hash} 65c02 pkg alpha
	php buildTestAndRelease/publish/publish2repo.php $(ORIX_ROM).tgz ${hash} 65c02 tgz alpha
  
  


  

