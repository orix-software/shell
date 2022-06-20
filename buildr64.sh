make
cp shellus.rom k2022-2.r64
cat basicus2.rom >> k2022-2.r64
cat ../../kernel/mkdir_fix/kernelus.rom >> k2022-2.r64
cat ../../empty-rom/empty-rom.rom  >> k2022-2.r64
#cp k2022-2.r64 /s/devus.r64