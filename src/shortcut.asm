.define SHORTCUT_XEXEC  $01
.define SHORTCUT_VECTOR $02

; This code manage shortcuts from shell

.proc _manage_shortcut
    cmp     #'B'+$40
    beq     @start_shortcut
    cmp     #'L'+$40
    beq     @start_shortcut
    cmp     #'C'+$40
    beq     @start_shortcut
    cmp     #'N'+$40
    beq     @start_shortcut
    cmp     #'T'+$40
    beq     @start_shortcut
    cmp     #'G'+$40
    beq     @start_shortcut
    cmp     #'A'+$40
    beq     @start_shortcut

    bne     @exit

@start_shortcut:
    and     #%01111111 ; Remove ctrl/fonct

    tax
    dex
    ; Checking shift.define NO_LOAD_ROM $00

    lda     KBDSHT
    and     #%00000001
    cmp     #$01
    bne     @not_shift

@not_shift:
    lda     shortcut_action_type,x
    beq     @exit ;  if shortcut_high then shortcut does not exists
    cmp     #SHORTCUT_VECTOR
    beq     @launch_vector
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

    ; FIXME macro orixsdk
    lda     bash_struct_ptr
    ldy     bash_struct_ptr+1

    BRK_KERNEL XEXEC

@exit:
    lda     #$01 ; No shortcut found
    rts
@launch_vector:
    lda     shortcut_high,x
    beq     @exit ;  if shortcut_high then shortcut does not exists
    sta     RES+1
    lda     shortcut_low,x
    sta     RES

    jsr     @run
    ; When shortcut is successful we are here, we return $00
    lda     #$00 ; Successful
    rts

@run:
    jmp     (RES)

str_systemd:
    .asciiz "systemd"

str_exec_basic11:
    .asciiz "basic11"        ; B

str_exec_basic11_g:
    .asciiz "basic11 -g"     ; G

shortcut_low:
    .byte <str_systemd ; A
    .byte <str_exec_basic11 ; B
    .byte $00 ; C
    .byte $00 ; D
    .byte $00 ; E
    .byte $00 ; F
    .byte <str_exec_basic11_g ; G
    .byte $00 ; H
    .byte $00 ; I
    .byte $00 ; J
    .byte $00 ; K
    .byte <twillauncher ; L
    .byte $00 ; M
    .byte <network_start ; N
    .byte $00 ; O
    .byte $00 ; P
    .byte $00 ; Q
    .byte $00 ; R
    .byte $00 ; S
    .byte <twilfirmware ; T
shortcut_high:
    .byte >str_systemd
    .byte >str_exec_basic11 ; B
    .byte $00 ; C
    .byte $00 ; D
    .byte $00 ; E
    .byte $00 ; F
    .byte >str_exec_basic11_g ; G
    .byte $00 ; H
    .byte $00 ; I
    .byte $00 ; J
    .byte $00 ; K
    .byte >twillauncher ; L
    .byte $00; M
    .byte >network_start ; N
    .byte $00 ; O
    .byte $00 ; P
    .byte $00 ; Q
    .byte $00 ; R
    .byte $00 ; S
    .byte >twilfirmware ; T
shortcut_action_type:
    .byte SHORTCUT_XEXEC
    .byte SHORTCUT_XEXEC ; B
    .byte $00 ; C
    .byte $00 ; D
    .byte $00 ; E
    .byte $00 ; F
    .byte SHORTCUT_XEXEC ; G
    .byte $00 ; H
    .byte $00 ; I
    .byte $00 ; J
    .byte $00 ; K
    .byte SHORTCUT_VECTOR ; L
    .byte $00; M
    .byte SHORTCUT_VECTOR ; N
    .byte $00 ; O
    .byte $00 ; P
    .byte $00 ; Q
    .byte $00 ; R
    .byte $00 ; S
    .byte SHORTCUT_VECTOR ; T

.endproc

