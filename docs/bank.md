# bank

### Displays bank or switch a bank

## SYNOPSYS
+ bank

## DESCRIPTION
This command displays bank when the command is called without parameter. WIth a parameter, you can switch to a the id of the bank passed to the argument :

bank : displays all the bank (if a signature is found)
bank 4 : switch to bank 4
bank -a : displauys all bank (empty bank too)

## SOURCE
https://github.com/orix-software/shell/blob/master/src/commands/bank.asm
