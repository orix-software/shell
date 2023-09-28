.export _man

; TODO : move MALLOC macro after arg test : it avoid a malloc if there is no parameter on command line

.proc _man
    MAN_SAVE_MALLOC_PTR :=userzp
    MAN_FP              :=userzp+2
    man_xmainargs_ptr   :=userzp+4
    man_buffer          :=userzp+6
    man_buffer_size     :=userzp+8
    man_ptr1            :=userzp+10
    man_buffer_bkp      :=userzp+12


    lda     #$00 ; return args with cut
    BRK_KERNEL XMAINARGS
    sta     man_xmainargs_ptr
    sty     man_xmainargs_ptr+1
    cpx     #$01 ; No args ?
    bne     start_man
    jmp     error_arg
start_man:
    ;
    MALLOC  (.strlen("/usr/share/man/")+FNAME_LEN+1+4)             ; length of /usr/share/man/ + 8 + .hlp + \0
    ; FIXME test OOM
    TEST_OOM


    sta     MAN_SAVE_MALLOC_PTR
    sta     RESB
    sty     MAN_SAVE_MALLOC_PTR+1
    sty     RESB+1

    lda     #<man_path
    sta     RES
    lda     #>man_path
    sta     RES+1
    jsr     _strcpy               ; MAN_SAVE_MALLOC_PTR contains adress of a new string

    ldx     #$01 ; get arg
    lda     man_xmainargs_ptr
    ldy     man_xmainargs_ptr+1
    BRK_KERNEL XGETARGV

    sta     RESB
    sty     RESB+1

    lda     MAN_SAVE_MALLOC_PTR
    sta     RES
    lda     MAN_SAVE_MALLOC_PTR+1
    sta     RES+1
    jsr     _strcat

    lda     #<str_man_hlp
    sta     RESB
    lda     #>str_man_hlp
    sta     RESB+1

    lda     MAN_SAVE_MALLOC_PTR
    sta     RES
    lda     MAN_SAVE_MALLOC_PTR+1
    sta     RES+1
    jsr     _strcat


    fopen (MAN_SAVE_MALLOC_PTR), O_RDONLY
    cpx     #$FF
    bne     next

    cmp     #$FF
    bne     next

    ; Not found
    ; Free memory for path
    lda     MAN_SAVE_MALLOC_PTR
    ldy     MAN_SAVE_MALLOC_PTR+1
    BRK_KERNEL XFREE

    print   txt_file_not_found, SAVE

    ldx     #$01 ; get arg
    lda     man_xmainargs_ptr
    ldy     man_xmainargs_ptr+1
    BRK_KERNEL XGETARGV
    BRK_KERNEL XWSTR0

    crlf

    rts
error:
    ; Free memory for path
    lda     MAN_SAVE_MALLOC_PTR
    ldy     MAN_SAVE_MALLOC_PTR+1
    BRK_KERNEL XFREE
error_arg:
    print   str_man_error
    rts

next:
    sta     MAN_FP
    stx     MAN_FP+1

    malloc  1080,man_buffer,str_oom
    cmp     #$00
    bne     @continue
    cpy     #$00
    bne     @continue
    rts
@continue:

    SWITCH_OFF_CURSOR
@readagain:
    CLS
    lda     man_buffer
    sta     man_buffer_bkp
    lda     man_buffer+1
    sta     man_buffer_bkp+1
  ; We read 1080 bytes

    fread (man_buffer), 1080, 1, MAN_FP
    sta     man_buffer_size
    stx     man_buffer_size+1
    cmp     #$00
    bne     @display
    cpx     #$00
    beq     out


@display:
    lda     #<$BB80
    sta     man_ptr1
    lda     #>$BB80
    sta     man_ptr1+1

    ldx     #05
    ldy     #$00
@L1:
    lda     man_buffer_size
    bne     @dec
    lda     man_buffer_size+1
    beq     @readkeyboard ; branch when NUM = $0000 (NUM is not decremented in that case)
    dec     man_buffer_size+1
@dec:
    dec     man_buffer_size

    lda     (man_buffer),y
    sta     (man_ptr1),y

    iny
    bne     @L1
    inc     man_buffer+1
    inc     man_ptr1+1
    dex
    bne     @L1


@readkeyboard:

    BRK_KERNEL XRDW0
    cmp     #27
    jmp     @readagain
    ; A bit crap to flush screen ...
    ; read again ?
out:
    BRK_KERNEL XHIRES
    BRK_KERNEL XTEXT

    SWITCH_ON_CURSOR

    lda     MAN_SAVE_MALLOC_PTR
    ldy     MAN_SAVE_MALLOC_PTR+1
    BRK_KERNEL XFREE

    fclose(MAN_FP)

    rts

str_man_error:
  .byte   "What manual page do you want?",$0D,$0A,0

man_path:
  .asciiz "/usr/share/man/"

str_man_hlp:
  .asciiz ".hlp"
.endproc
