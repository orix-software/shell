#! /bin/sh
make
cat shellus.rom > kernbeta.r64
cat ../../kernel/develop/basicus2.rom >> kernbeta.r64
cat ../../kernel/fixFDopen/kernelus.rom >> kernbeta.r64
cat ../../empty-rom/empty-rom.rom >> kernbeta.r64
cp kernbeta.r64 /s
