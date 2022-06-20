.include "telestrat.inc"

     print creating
     print file1
     crlf

     lda   #<file1
     ldx   #>file1
     BRK_TELEMON XMKDIR
     rts
creating
    .asciiz "Creating ... "
file1
    .asciiz "/jede/toulou/pouet"



