

.proc _meminfo
MALLOC_TABLE=48
    PRINT strMemTotal 
    
    lda MEMTOTAL
    sta RES
    lda MEMTOTAL+1
    sta RES+1
    lda MEMTOTAL+2
    sta RESB  
    lda MEMTOTAL+3
    sta RESB+1
    BRK_ORIX XDIVIDE_INTEGER32_BY_1024
    


    lda RES
    LDY RES+1
    LDX #$20 ;
    STX DEFAFF
    LDX #$03
    BRK_ORIX XDECIM
    PRINT strKB 
    
    PRINT strMemFree
    
    lda ORIX_MALLOC_FREE_SIZE_LOW_TABLE
    sta RES
    lda ORIX_MALLOC_FREE_SIZE_HIGH_TABLE
    sta RES+1
    lda #$00
    sta RESB  
    sta RESB+1
    BRK_ORIX XDIVIDE_INTEGER32_BY_1024
    
    lda RES
    LDY RES+1
    LDX #$20 ;
    STX DEFAFF
    LDX #$04
    BRK_ORIX XDECIM
    
    PRINT strKB
    rts
strMemTotal:
    .asciiz "MemTotal:"
strMemFree:
    .asciiz "MemFree:"
strKB:
    .byte " KB",$0A,$0D,0
.endproc

