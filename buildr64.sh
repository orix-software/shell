
ROM_NAME=devus.r64
cp shellus.rom $ROM_NAME
cat basicus2.rom >> $ROM_NAME
cat ../../kernel/develop/kernelus.rom >> $ROM_NAME
cat ../../empty-rom/empty-rom.rom  >> $ROM_NAME
#cp k2022-2.r64 /s/devus.r64