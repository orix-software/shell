.include "zeropage.inc"



.export _meminfo

   meminfo_ptr_malloc     := userzp
   meminfo_tmp1           := userzp+2


.proc _meminfo

    PRINT strMemTotal 

    ldx     #XVARS_KERNEL_MALLOC ; Get adress struct of malloc from kernel
    BRK_ORIX(XVARS)
    sta     meminfo_ptr_malloc
    sty     meminfo_ptr_malloc+1
    ldy     #(kernel_malloc_struct::kernel_malloc_max_memory_main)

    lda     (meminfo_ptr_malloc),y
    sta     meminfo_tmp1 

    ldy     #$00
    LDX     #$20 ;
    STX     DEFAFF
    LDX     #$03
    BRK_ORIX XDECIM
    PRINT   strKB 
    
    PRINT   strMemFree
    

    ldy     #kernel_malloc_struct::kernel_malloc_free_chunk_size_low
    lda     (meminfo_ptr_malloc),y


    sta     RES
    ldy     #kernel_malloc_struct::kernel_malloc_free_chunk_size_high
    lda     (meminfo_ptr_malloc),y
    
    sta     RES+1
    lda     #$00
    sta     RESB  
    sta     RESB+1
    BRK_ORIX XDIVIDE_INTEGER32_BY_1024
    
    lda     RES
    ldy     RES+1
    ldx     #$20 ;
    stx     DEFAFF
    ldx     #$04
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

