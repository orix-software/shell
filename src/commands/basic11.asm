.export _basic11

basic11_TXTPTR          := $E9

basic11_tmp := userzp

basic11_ptr1 := userzp+1
basic11_ptr2 := userzp+3

.struct  basic11_struct
  path                 .res 50   
.endstruct


.proc _basic11
    COPY_CODE_TO_BOOT_ATMOS_ROM_ADRESS := $200

    jmp     @start
    ldx     #$01
    jsr     _orix_get_opt
    ; get parameter
    bcc     @noparam      ; if there is no args, let's displays all banks

    STRCPY  ORIX_ARGV,BUFNOM
    PRINT ORIX_ARGV
    rts
    ; Check if it's a .tap
    lda     #<ORIX_ARGV
    sta     basic11_ptr1

    lda     #>ORIX_ARGV
    sta     basic11_ptr1+1

    ldy     #$00
@L1:
    lda     (basic11_ptr1),y
    beq     @found_end
    iny
    bne     @L1
    ; overflow open current only
    jmp     @open_current_cwd
@found_end:
    ; we are on the end of the arg
    dey    ; we reach the last char char
    lda    (basic11_ptr1),y
    cmp    #'p'    ; is it p for .taP?
    bne    @open_current_cwd ; no
    dey
    cmp    #'a'    ; is it a for .tAp ?
    bne    @open_current_cwd ; no
    dey
    cmp    #'t'    ; is it a for .Tap ?
    bne    @open_current_cwd ; no        
    dey
    cmp    #'.'    ; is it a for .tap ?
    bne    @open_current_cwd ; no   
    ; it's a tape file fill TXTPTR     
    ; let's reach first / or space
    dey
    lda    (basic11_ptr1),y
    cmp    #' ' ; fill with space
    beq    @fill_txt_ptr


@fill_txt_ptr:
    iny
    lda    basic11_ptr1
    sta    basic11_TXTPTR

    lda    basic11_ptr1+1
    sta    basic11_TXTPTR+1   

    tya
    clc
    adc    basic11_TXTPTR
    bcc    @do_not_inc
    inc    basic11_TXTPTR+1   
@do_not_inc:
    sta    basic11_TXTPTR

    lda    basic11_TXTPTR
    ldy    basic11_TXTPTR+1
    BRK_KERNEL XWSTR0 


@open_current_cwd:
    ; Open args
    lda     #<ORIX_ARGV
    ldx     #>ORIX_ARGV
    
    ldy     #O_RDONLY

    BRK_KERNEL XOPEN ; open current

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
loop:
    lda     #$00                                    ; FIXME 65C02
    sta     $00,x
    sta     COPY_CODE_TO_BOOT_ATMOS_ROM_ADRESS,x
    lda     copy,x
    sta     COPY_CODE_TO_BOOT_ATMOS_ROM_ADRESS,x
    dex
    bne     loop
    lda     #$00                                    ; FIXME 65C02
    sta     $2DF ; Flush keyboard for atmos rom


    jmp     COPY_CODE_TO_BOOT_ATMOS_ROM_ADRESS
copy:
    sei
    pla
    sta     STORE_CURRENT_DEVICE ; For atmos ROM : it pass the current device ()
    lda     #ATMOS_ID_BANK
    sta     VIA2::PRA
    jmp     $F88F ; NMI vector of ATMOS rom
.endproc
