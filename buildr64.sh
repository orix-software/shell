make
cp shellus.rom kerbank.r64
cat ../../kernel/develop/basicus2.rom >> kerbank.r64
cat ../../kernel/develop/kernelus.rom >> kerbank.r64
cat tests/romstests/rom8.rom >> kerbank.r64
cp kerbank.r64 /s/