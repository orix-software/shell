make
cp shellus.rom k2022-1.r64
cat ../../kernel/develop/basicus1.rom >> k2022-1.r64
cat ../../kernel/develop/kernelus.rom >> k2022-1.r64
cat ../../empty-rom/empty-rom.rom  >> k2022-1.r64
cp k2022-1.r64 /s/devus.r64