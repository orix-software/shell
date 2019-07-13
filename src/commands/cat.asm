.IFP02
    .macro bra _label
        jmp _label
    .endmacro
.endif

.proc _cat
    ldx #$01
    jsr _orix_get_opt
    bcc print_usage

    jsr _ch376_verify_SetUsbPort_Mount
    ;cmp #$01
    ;BEQ cat_error_param
    ; Suppose que _ch376_verify_SetUsbPort_Mount renvoie C=1 si tout va bien
    bcc cat_error_param

    jsr _cd_to_current_realpath_new

    ldx #$01
    jsr _orix_get_opt

    STRCPY  ORIX_ARGV,BUFNOM
    jsr _ch376_set_file_name

    jsr _ch376_file_open
    cmp #CH376_ERR_MISS_FILE
    bne read_byte

    PRINT BUFNOM
    PRINT str_not_found
rts

print_usage:
cat_error_param:
    PRINT txt_usage
rts

read_byte:
    lda #$FF
    tay
    jsr _ch376_set_bytes_read
    ; Renvoie CH376_USB_INT_SUCCESS ($14) si le fichier est vide, CH376_USB_INT_DISK_READ ($1D) si ok

    continue:
    we_read:
    @ZZ0001:
        cmp #CH376_USB_INT_DISK_READ
        bne @ZZ0002

            lda #CH376_RD_USB_DATA0
            sta CH376_COMMAND
            lda CH376_DATA
            sta userzp
            ; Tester si userzp == 0?

            @ZZ0003:
                lda CH376_DATA
                cmp #$0A
                bne autre
                    BRK_TELEMON XCRLF
                    bra next
            autre:
                cmp #$0D
                beq next
                    BRK_TELEMON XWR0
            next:
                dec userzp

            bne @ZZ0003

            lda #CH376_BYTE_RD_GO
            sta CH376_COMMAND
            jsr _ch376_wait_response
            ; _ch376_wait_response renvoie 1 en cas d'erreur et le CH376 ne renvoie pas de valeur 0
            ; donc le bne devient un saut inconditionnel!

    ;jmp @ZZ0001
    bne @ZZ0001

    ; Tester si ACC==1 pour détecter une éventuelle erreur?

    @ZZ0002:
    end_cat:
    finished:
    BRK_TELEMON XCRLF
rts

txt_usage:
    .BYT "usage: cat FILE",$0D,$0A,0

.endproc
