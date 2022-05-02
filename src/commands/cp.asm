.include "commands/lib/common.asm"

CP_SIZE_OF_BUFFER=40000



cp_mv_rm_argv_ptr       := userzp ; 16 bits
cp_mv_rm_argc           := userzp+2 ; 8 bits
cp_tmp                  := userzp+4
cp_mv_rm_save_argv_ptr  := userzp+6
cp_mv_rm_save_argv_ptr2 := userzp+8


.export _mv,_cp

;.proc
.proc _mv
  rts
  lda   #$01 ; don't Delete param1 file
  sta   cp_tmp
  jmp   _cp_mv_execute
.endproc  

.proc _cp
  rts
  lda     #$00 ; don't Delete param1 file FIXME 65c02
  sta    cp_tmp
  jmp   _cp_mv_execute
.endproc

.proc _cp_mv_execute
    ptr1         :=userzp
    MALLOC_PTR1  :=userzp+2
    ;ptr2 will be used to save fp
    lda   #$00
    sta   ptr1_32         ; FIXME 65C02
    sta   ptr1_32+1
    sta   ptr1_32+2
    sta   ptr1_32+3
    jsr   commands_check_2_params
    beq   @next
    rts
  
@next:
  ; open first params


    XMAINARGS = $2C
    XGETARGV =  $2E


    BRK_KERNEL XMAINARGS

    sta     cp_mv_rm_argv_ptr
    sty     cp_mv_rm_argv_ptr+1
    stx     cp_mv_rm_argc

;cp_mv_rm_argv_ptr := userzp ; 16 bits
;cp_mv_rm_argc     := userzp+2 ; 8 bits
;cp_tmp            := userzp+4

    ldx     #$01
    lda     cp_mv_rm_argv_ptr
    ldy     cp_mv_rm_argv_ptr+1

    BRK_KERNEL XGETARGV

    sta     cp_mv_rm_save_argv_ptr
    sty     cp_mv_rm_save_argv_ptr+1


    fopen (cp_mv_rm_save_argv_ptr),#O_RDONLY 
 

    cmp     #$FF
    beq     no_such_file

  ; Let's copy
  
  ; Send the fp pointer

    sta     TR0
  ; define target address
      
    MALLOC CP_SIZE_OF_BUFFER
    sta     MALLOC_PTR1
    sty     MALLOC_PTR1+1

    ;MALLOC(209)
    cmp     #$00
    bne     @not_oom
    cpy     #$00
    bne     @not_oom
    print   str_oom,NOSAVE
    ; oom
    rts
  @not_oom:  
    sta     PTR_READ_DEST
    sta     ptr1

    sty     ptr1+1
    sty     PTR_READ_DEST+1
  ; We read 8000 bytes
    lda     #<CP_SIZE_OF_BUFFER
    ldy     #>CP_SIZE_OF_BUFFER
  ; reads byte 
    BRK_TELEMON XFREAD
    ; Compute bytes written
    lda     PTR_READ_DEST+1
    sec
    sbc     ptr1+1
    sta     ptr1+1
    ;tax			
    lda     PTR_READ_DEST
    sec
    sbc     ptr1
    sta     ptr1


  BRK_TELEMON XCLOSE
 
    ldx     #$02
    lda     cp_mv_rm_argv_ptr
    ldy     cp_mv_rm_argv_ptr+1

    BRK_KERNEL XGETARGV

    sta     cp_mv_rm_save_argv_ptr2
    sty     cp_mv_rm_save_argv_ptr2+1


    fopen (cp_mv_rm_save_argv_ptr2),#O_WRONLY


    lda     MALLOC_PTR1
    sta     PTR_READ_DEST
    lda     MALLOC_PTR1+1
    sta     PTR_READ_DEST+1
  ; We read 8000 bytes
    lda     ptr1
    ldy     ptr1+1
  ; reads byte 
    BRK_KERNEL XFWRITE

    BRK_KERNEL XCLOSE
    ; and we write the file
    
    lda     cp_tmp
    beq     @out
    
    lda     cp_mv_rm_save_argv_ptr2
    ldx     cp_mv_rm_save_argv_ptr2+1


    BRK_KERNEL XRM
    ; now remove file

@out:
  
    rts
  no_such_file:
    print   cp,NOSAVE
    CPUTC   ':'
    CPUTC   ' ' 
    print   str_cannot_stat,NOSAVE
    CPUTC   '''
  
    print (cp_mv_rm_save_argv_ptr2),NOSAVE
  

  lda     #$27
  BRK_KERNEL XWR0
  
  print   str_not_found,NOSAVE
  rts
str_cannot_stat:
  .asciiz   "cannot stat "

.endproc
