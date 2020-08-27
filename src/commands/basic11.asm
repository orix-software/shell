.export _basic11

basic11_tmp := userzp

basic11_ptr1 := userzp+1
basic11_ptr2 := userzp+3

basic11_tmp0 := userzp+5
basic11_tmp1 := userzp+6
basic11_found := userzp+7


;/etc/basic/a/12345678.cnf
.define basic11_sizeof_max_length_of_conf_file_bin 100 ; used for the path but also for the cnf content

.define basic11_sizeof_binary_conf_file 1+4+1+1 ; Rom + direction + fire1 + fire2 + fire3

.struct  basic11_struct
  path_conf                 .res basic11_sizeof_max_length_of_conf_file_bin ; /etc/basic/a/12345678.cnf + \0
.endstruct

.proc _basic11
    COPY_CODE_TO_BOOT_ATMOS_ROM_ADRESS := $200

    jmp     @start
    ldx     #$01
    jsr     _orix_get_opt
    ; get parameter
    bcc     @noparam      ; if there is no args, let's start


    lda     #basic11_sizeof_max_length_of_conf_file_bin
    ldy     #$00
    BRK_KERNEL XMALLOC
    sta     basic11_ptr1

    sty     basic11_ptr1+1


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
    lda     #'c'
    sta     (basic11_ptr1),y
    iny
    lda     #'n'
    sta     (basic11_ptr1),y    
    iny
    lda     #'f'
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
    sta     $00,x
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
    lda     basic11_ptr1
    sta     PTR_READ_DEST
    
    lda     basic11_ptr1+1
    sta     PTR_READ_DEST+1

  ; We read the file with the correct
    lda     #<basic11_sizeof_binary_conf_file
    ldy     #>basic11_sizeof_binary_conf_file
  ; reads byte 
    BRK_KERNEL XFREAD
    BRK_KERNEL XCLOSE

    ; Find arg up
    lda     #<str_up
    sta     basic11_ptr2
    lda     #>str_up
    sta     basic11_ptr2+1

    jsr     @find_param

    rts
@find_param:    
    ; We found a conf
    
    ldy     #$00
    sty     basic11_tmp0
    sty     basic11_found
@L4:    
    lda     (basic11_ptr2),y ; Get char to string
@loopme:
    jmp @loopme    
    sta     $bb80+120
    beq     @getarg 
    sty     basic11_tmp1

    ldy     basic11_tmp0
    cmp     (basic11_ptr1),y ; compare with conf loaded in RAM
    bne     @S10
    ; Found ?
    sta     $bb80,y
    lda     #$01
    sta     basic11_found
    inc     basic11_tmp1

@S10:
    iny
    sty     basic11_tmp0    
    ldy     basic11_tmp1

    BRK_KERNEL XWR0
    iny
    cpy     #60
    bne     @L4
    rts
@getarg:
    lda     basic11_found
    bne     @found
    ; If not found return 0
    lda     #$00
    rts
@found:    
    RETURN_LINE
    ldy     basic11_tmp0
@L11:    
    lda     (basic11_ptr1),y
    cmp     #$0A
    beq     @out_get_arg
    cmp     #$0D
    beq     @out_get_arg    
    BRK_KERNEL XWR0
    iny
    bne     @L11
@out_get_arg:    
    rts
str_up:
    .asciiz "up="
str_down:
    .asciiz "down="
str_right:
    .asciiz "right="
str_left:
    .asciiz "left="
str_fire1:
    .asciiz "fire1="
str_rom:
    .asciiz "rom="            

basic_conf_str:
    .asciiz "/var/cache/basic11/"
.endproc
