make
cp shellus.rom kerbank.r64
cat ../../kernel/develop/basicus2.rom >> kerbank.r64
cat ../../kernel/develop/kernelus.rom >> kerbank.r64
cat ../../empty-rom/empty-rom.rom >> kerbank.r64
cp kerbank.r64 /s/