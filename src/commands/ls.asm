NUMBER_OF_COLUMNS_LS = 3

.proc _ls
    lda #NUMBER_OF_COLUMNS_LS+1
    sta NUMBER_OF_COLUMNS

    jsr _ch376_verify_SetUsbPort_Mount
    bcc @ZZ0001
        jsr _cd_to_current_realpath_new
        ldx #$01
        jsr _orix_get_opt

        STRCPY ORIX_ARGV, BUFNOM

        lda BUFNOM
        bne @ZZ0002
            lda #"*"
            sta BUFNOM
            lda #$00
            sta BUFNOM+1

        @ZZ0002:
        jsr _ch376_set_file_name
        jsr _ch376_file_open
        ; Au retour, on peut avoir USB_INT_SUCCESS ou USB_INT_DISK_READ)

        ; $14 -> Fichier existant (USB_INT_SUCCESS) (cas 'ls fichie.ext')
        ; $1D -> Lecture OK (USB_INT_DISk_READ
        ; $41 -> Fin de liste (ERR_OPEN_DIR) ou ouverture répertoire (cas 'ls repertoire')
        ; $42 -> fichier inexistant (ERR_MISS_FILE)

        cmp #CH376_ERR_MISS_FILE
        beq Error

        @ZZ1001:
        cmp #CH376_USB_INT_SUCCESS
        bne @ZZ1002
            lda #COLOR_FOR_FILES
            bne display_one_file_catalog

        @ZZ1002:
        cmp #CH376_ERR_OPEN_DIR
        bne @ZZ0003
            lda #COLOR_FOR_DIRECTORY
            bne display_one_file_catalog

        ; cmp #CH376_USB_INT_SUCCESS
        ; bne @ZZ0003
        ;    lda #CH376_USB_INT_DISK_READ

        @ZZ0003:
            cmp #CH376_USB_INT_DISK_READ
            bne @ZZ0004
                lda #CH376_RD_USB_DATA0
                sta CH376_COMMAND
                lda CH376_DATA
                cmp #32
                beq @ZZ0005
                    rts

                @ZZ0005:
                jsr display_catalog

        ; display_one_file_catalog renvoie la valeur de _ch376_wait_response qui renvoie 1 en cas d'erreur
        ; et le CH376 ne renvoie pas de valeur 0
        ; donc le bne devient un saut inconditionnel!
        ; jmp @ZZ0003
        bne @ZZ0003

        @ZZ0004:
        BRK_ORIX XCRLF

    @ZZ0001:
    rts

; ------------------------------------------------------------------------------
Error:
    PRINT txt_file_not_found
    ldx #$01
    jsr _orix_get_opt
    .BYTE $2C

display_one_file_catalog:
    .BYTE $00, XWR0
    PRINT BUFNOM
    BRK_ORIX XCRLF
rts

; ------------------------------------------------------------------------------

display_catalog:
    lda #COLOR_FOR_FILES
    sta BUFNOM
    ldy #$01
    ldx #$01

    @ZZ0007:
        lda CH376_DATA
        cmp #' '
        beq @ZZ0008
            jsr _lowercase_char
            sta BUFNOM,y
            iny

        @ZZ0008:

        INX
        cpx #9
        bne @ZZ0009
            lda #'.'
            sta BUFNOM,Y
            STY TR5
            iny
        @ZZ0009:

        cpx #10
        bne @ZZ0010
            cmp #' '
            bne @ZZ0011
                lda TR5
                STY TR5
                tay
                lda #' '
                sta BUFNOM,Y
                ldy TR5
            @ZZ0011:
        @ZZ0010:
        cpx #12
    bne @ZZ0007

    lda CH376_DATA
    cmp #$10
    bne @ZZ0012
        lda #COLOR_FOR_DIRECTORY
        sta BUFNOM
        dey

    @ZZ0012:
    lda #$00
    sta BUFNOM,Y
    ;STY TEMP_ORIX_1

    ldx #20

    @ZZ0013:
        lda CH376_DATA
        dex
    bpl @ZZ0013

    lda BUFNOM
    cmp #'.'
    beq @ZZ0014
        lda BUFNOM+1
        cmp #'.'
        beq @ZZ0015
            dec NUMBER_OF_COLUMNS
            bne @ZZ0016
                BRK_ORIX XCRLF
                lda #NUMBER_OF_COLUMNS_LS
                sta NUMBER_OF_COLUMNS
            @ZZ0016:

            PRINT BUFNOM

            ;ldy TEMP_ORIX_1

            @ZZ0017:
                cpy #13
                beq @ZZ0018
                    iny
                    CPUTC ' '
            jmp @ZZ0017

            @ZZ0018:
        @ZZ0015:
    @ZZ0014:

    lda #CH376_FILE_ENUM_GO
    sta CH376_COMMAND
    jsr _ch376_wait_response
rts

optstring:
.BYT 'l',0

.endproc

