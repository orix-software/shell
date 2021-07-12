.proc _manage_shortcut

    cmp     #'B'+$40
    beq     @start_shortcut
    cmp     #'G'+$40
    bne     @exit
@start_shortcut:
    and     #%01111111 ; Remove ctrl/fonct

    tax
    dex

    lda     shortcut_high,x
    beq     @exit ;  if shortcut_high then shortcut does not exists
    sta     RES+1
    lda     shortcut_low,x
    sta     RES

    ldy     #shell_bash_struct::command_line
    sty     RESB+1

    ldy     #$00
    sty     RESB

    ldx     #$00
@L1:
    ldy     RESB        
    lda     (RES),y
    beq     @out
    iny
    sty     RESB        


    ldy     RESB+1
    sta     (bash_struct_ptr),y
    iny
    sty     RESB+1
    bne     @L1
@out:    
    sta     (bash_struct_ptr),y
    
    
    lda     bash_struct_ptr
    ldy     bash_struct_ptr+1

    BRK_KERNEL XEXEC
@exit:
    rts
str_exec_basic11:
    .asciiz "basic11"        ; B
str_exec_basic11_g:
    .asciiz "basic11 -g"     ; G
shortcut_low:
    .byte $00 ; A 
    .byte <str_exec_basic11 ; B
    .byte $00 ; C    
    .byte $00 ; D    
    .byte $00 ; E 
    .byte $00 ; F
    .byte <str_exec_basic11_g ; G

shortcut_high:
    .byte $00
    .byte >str_exec_basic11 ; B
    .byte $00 ; C    
    .byte $00 ; D    
    .byte $00 ; E 
    .byte $00 ; F    
    .byte >str_exec_basic11_g ; G
    

.endproc    
