.include "telestrat.inc"

     PRINT creating
     PRINT file1
     RETURN_LINE

     lda   #<file1
     ldx   #>file1
     BRK_TELEMON XMKDIR
     rts
creating
    .ASCIIZ "Creating ... "  
file1
    .ASCIIZ "/jede/toulou/pouet"
  


