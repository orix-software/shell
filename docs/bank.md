# bank

## Introduction

Bank command is command line tool to see which bank are loaded into EEPROM bank and RAM bank. Each bank has a
"signature". Bank allows to see theses banks.
Bank can also starts a ROM with his id. In that case, you don’t need to have a rom "orix friendly" and you can start it
from command line. In the current bank version, there is restriction to launch a command.

## SYNOPSYS

### List all bank (when ROM signature is valid)

/#bank
Bank 1 to 32 is eeprom bank and bank 33 to 64 are ram bank

### Displays all signature even when ROM is not valid

/#bank

### List all commands from a bank

/#help -b5

### Start a specific bank

/#bank 1

If you need to load a rom into a bank, you need to have a look to orixcfg binar

## DESCRIPTION

This command displays bank when the command is called without parameter. WIth a parameter, you can switch to a the id of the bank passed to the argument :

bank : displays all the bank (if a signature is found)
bank 4 : switch to bank 4
bank -a : displauys all bank (empty bank too)

## SOURCE

https://github.com/orix-software/shell/blob/master/src/commands/bank.asm
