;.include "commands/lib/common.asm"


; Ne pas augmenter la taille car avec submit, cela fera trop
CP_SIZE_OF_BUFFER=1000

cp_mv_rm_argv_ptr       := userzp   ; 16 bits
cp_mv_rm_argc           := userzp+2 ; 8 bits
cp_tmp                  := userzp+4
cp_mv_rm_save_argv_ptr  := userzp+6
cp_mv_rm_save_argv_ptr2 := userzp+8
cp_mv_fp_src            := userzp+10
cp_mv_fp_dest           := userzp+12
cp_mv_fp_dest_nb_bytes  := userzp+14

.export _mv,_cp

.proc _mv
    lda     #$01 ; don't Delete param1 file
    sta     cp_tmp
    jmp     _cp_mv_execute
.endproc

.proc _cp
    lda     #$00 ; don't Delete param1 file FIXME 65c02
    sta     cp_tmp
    jmp     _cp_mv_execute
.endproc

.proc _cp_mv_execute
    ptr1         :=userzp
    MALLOC_PTR1  :=userzp+2
    ;ptr2 will be used to save fp
    lda     #$00
    sta     ptr1_32         ; FIXME 65C02
    sta     ptr1_32+1
    sta     ptr1_32+2
    sta     ptr1_32+3
    jsr     commands_check_2_params
    beq   @next

    rts

@next:
  ; open first params
; $ffbd
    XMAINARGS = $2C
    XGETARGV =  $2E

    initmainargs cp_mv_rm_argv_ptr, cp_mv_rm_argc, 0

    cpx     #$03
    beq     allargs
    print   usage
    crlf
    rts

allargs:
    getmainarg #1, (cp_mv_rm_argv_ptr)
    sta     cp_mv_rm_save_argv_ptr
    sty     cp_mv_rm_save_argv_ptr+1


    getmainarg #2, (cp_mv_rm_argv_ptr)
    sta     cp_mv_rm_save_argv_ptr2
    sty     cp_mv_rm_save_argv_ptr2+1

    ; checking of the arg is not empty
    ldy     #$00
    lda     (cp_mv_rm_save_argv_ptr2),y
    bne     arg2_not_empty
    print   error_second_arg_empty
    rts

arg2_not_empty:
    fopen (cp_mv_rm_save_argv_ptr),O_RDONLY,,cp_mv_fp_src
    cpx     #$FF
    bne     continue

    cmp     #$FF
    bne     continue
    jmp     no_such_file

continue:
    fopen (cp_mv_rm_save_argv_ptr2),O_WRONLY|O_CREAT,,cp_mv_fp_dest
    cpx     #$FF
    bne     continue2
    cmp     #$FF
    bne     continue2
    jmp     no_such_file2

continue2:
    malloc  #CP_SIZE_OF_BUFFER
    sta     MALLOC_PTR1
    sty     MALLOC_PTR1+1
    cmp     #$00
    bne     @loop_until_eof
    cpy     #$00
    bne     @loop_until_eof
    print   str_oom
    ; oom
    rts

@loop_until_eof:

    fread (MALLOC_PTR1), CP_SIZE_OF_BUFFER, 1, cp_mv_fp_src

    sta     cp_mv_fp_dest_nb_bytes
    stx     cp_mv_fp_dest_nb_bytes+1

    cmp     #$00
    bne     @continue_to_write
    cpx     #$00
    bne     @continue_to_write

    jmp     @copy_finished

@continue_to_write:

    fwrite (MALLOC_PTR1), (cp_mv_fp_dest_nb_bytes), 1, cp_mv_fp_dest
    jmp     @loop_until_eof

@copy_finished:
    fclose(cp_mv_fp_src)
    fclose(cp_mv_fp_dest)
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
    print   cp
    print   #':'
    print   #' '
    print   str_cannot_stat
    print   #'''

    print (cp_mv_rm_save_argv_ptr)
    lda     #$27
    BRK_KERNEL XWR0

    print   str_not_found
    crlf
    rts

no_such_file2:
    print   cp
    print   #':'
    print   #' '
    print   str_cannot_stat
    print   #'''

    print (cp_mv_rm_save_argv_ptr2)
    lda     #$27
    BRK_KERNEL XWR0

    print   str_not_found
    crlf
    rts

usage:
    .asciiz "cp fromfile tofile"

error_second_arg_empty:
    .asciiz "Missing second arg"

.endproc

str_cannot_stat:
    .asciiz   "cannot stat "

.proc commands_check_2_params
    ldx     #$00
    rts

str_missing_operand_after:
    .asciiz "missing destination file operand after '"
.endproc
