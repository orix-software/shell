.export _basic11

basic11_tmp   := userzp

basic11_ptr1  := userzp+1
basic11_ptr2  := userzp+3

basic11_tmp0  := userzp+5
basic11_tmp1  := userzp+6
basic11_found := userzp+7
basic11_stop  := userzp+8

.define BASIC11_PATH_DB "/var/cache/basic11/"
.define BASIC11_PATH_ROM "/usr/share/basic11/basic" ; basicsdX basicusX ...
.define BASIC11_MAX_MAINDB_LENGTH 10000

;/etc/basic/a/12345678.cnf
.define basic11_sizeof_max_length_of_conf_file_bin .strlen(BASIC11_PATH_DB)+1+1+8+1+2+1 ; used for the path but also for the cnf content

.define basic11_sizeof_binary_conf_file 7 ; Rom + direction + fire1 + fire2 + fire3

.proc _basic11
    COPY_CODE_TO_BOOT_ATMOS_ROM_ADRESS := $200

    ;jmp     @start
    ldx     #$01
    jsr     _orix_get_opt
    ; get parameter
    bcc     @start      ; if there is no args, let's start

    lda     ORIX_ARGV
    cmp     #'-'
    bne     @is_a_tape_file_in_arg
    jmp     @basic11_option_management

@is_a_tape_file_in_arg:
    lda     #basic11_sizeof_max_length_of_conf_file_bin
    ldy     #$00
    BRK_KERNEL XMALLOC
    sta     basic11_ptr1

    sty     basic11_ptr1+1

@no_check_param:

    ldy     #$00
@L2:    
    lda     basic_conf_str,y
    beq     @outcpy
    sta     (basic11_ptr1),y 
    iny
    bne     @L2

@outcpy:


    ; do strcat
    ; get letter
    ldx     #$01      ; skip double quote and get first char
    lda     ORIX_ARGV,x
    sta     (basic11_ptr1),y
    iny
    lda     #'/' ; add /
    sta     (basic11_ptr1),y ; get another letter
   
    iny

@L3:    
    lda     ORIX_ARGV,x
    cmp     #$22 ; " char
    beq     @outstrcat
    cmp     #$00
    beq     @outstrcat
    sta     (basic11_ptr1),y ; get another letter
    iny
    inx     
    bne     @L3
@outstrcat:
    ; concat .cnf
    lda     #'.'
    sta     (basic11_ptr1),y
    iny
    lda     #'d'
    sta     (basic11_ptr1),y
    iny
    lda     #'b'
    sta     (basic11_ptr1),y    
    iny
    lda     #$00 ; store end of string
    sta     (basic11_ptr1),y    


    ldx     basic11_ptr1+1
    lda     basic11_ptr1

    ldy     #O_RDONLY

    BRK_KERNEL XOPEN ; open current

    cpy     #$00
    bne     @parsecnf ; not null then  start because we did not found a conf
    cmp     #$00
    beq     @noparam_free ; not null then  start because we did not found a conf
    bne     @parsecnf


    ;STRCPY  ORIX_ARGV,BUFNOM
    ;PRINT ORIX_ARGV
    ;rts
    ; Check if it's a .tap
@noparam_free:

    lda     basic11_ptr1
    ldy     basic11_ptr1+1

    BRK_KERNEL XFREE
    jmp     @start


@noparam:
    ; Get current pwd and open
    BRK_KERNEL XGETCWD  ; Get A & Y 
    sty     basic11_tmp
    ldx     basic11_tmp
    ldy     #O_RDONLY

    BRK_KERNEL XOPEN ; open current

@start:
    sei
    

    ldx   #XVARS_KERNEL_CH376_MOUNT
    BRK_KERNEL XVARS
    sta   basic11_ptr2
    sty   basic11_ptr2+1
    
    ldy   #$00
    lda   (basic11_ptr2),y
    pha


    ; stop t2 from via1
    lda     #$00+32
    sta     VIA::IER
    ; stop via 2
    lda     #$00+32+64
    sta     VIA2::IER
	
    ldx     #$00
@loop:
    lda     #$00                                    ; FIXME 65C02
  ;  sta     $00,x
    sta     COPY_CODE_TO_BOOT_ATMOS_ROM_ADRESS,x
    lda     @copy,x
    sta     COPY_CODE_TO_BOOT_ATMOS_ROM_ADRESS,x
    dex
    bne     @loop
    lda     #$00                                    ; FIXME 65C02
    sta     $2DF ; Flush keyboard for atmos rom


    jmp     COPY_CODE_TO_BOOT_ATMOS_ROM_ADRESS
@copy:
    sei
    pla
    sta     STORE_CURRENT_DEVICE ; For atmos ROM : it pass the current device ()
    lda     #ATMOS_ID_BANK
    sta     VIA2::PRA

    jmp     $F88F ; NMI vector of ATMOS rom


@parsecnf:

  ; define target address
    lda     #$1 ; We read db version and rom version, and we write it, we avoid a seek to 2 bytes in the file
    sta     PTR_READ_DEST
    
    lda     #$00
    sta     PTR_READ_DEST+1

  ; We read the file with the correct
    lda     #<basic11_sizeof_binary_conf_file
    ldy     #>basic11_sizeof_binary_conf_file
  ; reads byte 
    BRK_KERNEL XFREAD

    BRK_KERNEL XCLOSE
    jmp     @noparam_free

@basic11_option_management:
    ldx     #$01
    lda     ORIX_ARGV,x
    cmp     #'l'
    bne     @option_not_known
    ; get second ARG
    ldx     #$02
    jsr     _orix_get_opt
 
    lda     #<(.strlen(BASIC11_PATH_DB)+8+4+1)
    ldy     #>(.strlen(BASIC11_PATH_DB)+8+4+1)
    BRK_KERNEL XMALLOC

    sta     basic11_ptr2
    sty     basic11_ptr2+1

    ldy     #$00
@L10:    
    lda     str_basic11_maindb,y
    beq     @S10
    sta     (basic11_ptr2),y
    iny
    bne     @L10
@S10:
    sta     (basic11_ptr2),y

    lda     basic11_ptr2
    ldx     basic11_ptr2+1


    ldy     #O_RDONLY

    BRK_KERNEL XOPEN ; open current
    cpy     #$00
    bne     @read_maindb ; not null then  start because we did not found a conf
    cmp     #$00
    bne     @read_maindb ; not null then  start because we did not found a conf
    
    PRINT   str_basic11_missing
    rts

@option_not_known:
    PRINT   str_basic11_not_known        
    rts


@read_maindb:
    lda     basic11_ptr2
    ldy     basic11_ptr2+1
    BRK_KERNEL XFREE



    lda     #<BASIC11_MAX_MAINDB_LENGTH
    ldy     #>BASIC11_MAX_MAINDB_LENGTH
    BRK_KERNEL XMALLOC

    sta     basic11_ptr1
    sty     basic11_ptr1+1

  ; define target address
    lda     basic11_ptr1 ; We read db version and rom version, and we write it, we avoid a seek to 2 bytes in the file
    sta     PTR_READ_DEST
    
    lda     basic11_ptr1+1
    sta     PTR_READ_DEST+1

  ; We read the file with the correct
    lda     #<BASIC11_MAX_MAINDB_LENGTH
    ldy     #>BASIC11_MAX_MAINDB_LENGTH
  ; reads byte 
    BRK_KERNEL XFREAD

    BRK_KERNEL XCLOSE    

    ; Search now
    PRINT   basic_str_search
    
    lda     ORIX_ARGV
    beq     @displays_all

    ldx     #$00
    ldy     #$00
@L11:    
    lda     (basic11_ptr1),y
    beq     @end_of_line
    cmp     ORIX_ARGV,x
    beq     @found
    cmp     #';' ; Check if end of key
    beq     @end_of_key
    cmp     #$FF 
    beq     @exit
    ; not found
    lda     #$01
    sta     basic11_found
@continue:    
    iny
    bne     @L11
    inc     basic11_ptr1+1
    jmp     @L11
@exit_search:
    PRINT   basic_str_last_line

@exit:
    lda     basic11_ptr1
    ldy     basic11_ptr1+1



    BRK_KERNEL XFREE

    ; Open
    rts
@end_of_line:    
    rts
@end_of_key:
    rts    
@found:
    lda     #$00
    sta     basic11_found
    rts
@displays_all:
    lda     #$01
    sta     basic11_stop ; Define that there is no space bar pressed

    ldx     #$00
    lda     #'|'
    BRK_KERNEL XWR0
    ldy     #$01
@L12:
    BRK_KERNEL XRD0
    bcs     @no_char_action
    pha
    asl     KBDCTC
    bcc     @no_ctrl
    pla
    BRK_KERNEL XCRLF
    rts
@no_ctrl:
    pla
    cmp     #' '
    bne     @no_char
    lda     basic11_stop
    beq     @inv_to_1

    lda     #$00
    sta     basic11_stop
    jmp     @L12

@inv_to_1:
    inc     basic11_stop
    jmp     @L12

@no_char_action:
    lda     basic11_stop
    beq     @L12
    ;bne     @L12
@no_char:    
    lda     (basic11_ptr1),y
    beq     @end_of_line_all
    cmp     #$FF
    beq     @exit_search
    cmp     #';'
    beq     @end_of_key_all
    cpx     #29
    beq     @end_of_line_all
    BRK_KERNEL XWR0
    inx
    
    iny
    bne     @L12
    inc     basic11_ptr1+1
    ldy     #$00
    jmp     @L12

@end_of_line_all:
    cpx     #29
    beq     @next2
    lda     #' '
    BRK_KERNEL XWR0
    inx     
    bne     @end_of_line_all
@next2:
    lda     (basic11_ptr1),y
    beq     @end_of_line_all_column
    iny
    bne     @next2
    inc     basic11_ptr1+1
    jmp     @next2
    ldy     #$FF
@end_of_line_all_column:
    lda     #'|'
    BRK_KERNEL XWR0
    lda     #'|'
    BRK_KERNEL XWR0    
    ldx     #$00
    iny
    jmp     @L12

@end_of_key_all:
    cpx     #$08
    beq     @next
    lda     #' '
    BRK_KERNEL XWR0
    inx     
    bne     @end_of_key_all
@next:    
    lda     #'|'
    BRK_KERNEL XWR0
    ldx     #$00
    iny
    jmp     @L12

str_basic11_not_known:
    .byte "Unknown option",$0D,$0A,$00

str_basic11_missing:
    .byte "Missing file : "
; don't put any other string here, the is no EOS because we earn one byte to displays message error with next path
str_basic11_maindb:
    .byte BASIC11_PATH_DB
    .asciiz "basic11.db"
basic_conf_str:
    .asciiz BASIC11_PATH_DB
basic_str_search:
    .byte  "+--------+-----------------------------+"
    .byte  "|  key   |            NAME             |"
    .byte  "+--------+-----------------------------+",0
basic_str_last_line:
    .byte  "--------+-----------------------------+",0
basic_rnd_init:
    .byte   $00
.endproc
