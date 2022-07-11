.define VERSION "2022.3"

.include   "telestrat.inc"
.include   "fcntl.inc"
.include   "build.inc"

.include   "dependencies/orix-sdk/macros/SDK.mac"
.include   "dependencies/orix-sdk/include/SDK.inc"

.include   "dependencies/kernel/src/include/keyboard.inc"
.include   "include/bash.inc"

.define HISTORY_MAX_NUMBER_ENTRY 20

userzp := $80 ; FIXME

savex   := userzp
savea   := userzp+1
saveptr := userzp+3
savepos := userzp+5



.org $c000
start_rom_entry:
        jmp     start
;c003
register_command_entry:
        jmp     register_command
;c006
ctrl_r_history:
        jmp     search_history
;c009
go_up_history:
        jmp     go_up_history_routine
;c00c
go_down_history:
        jmp     go_down_history_routine

go_up_history_routine:
        ;cli
        sta     saveptr
        sty     saveptr+1
        cpx     #$00            ;
        bne     @S1
        lda     next_current_position
        sta     history_entry_current_id
        jmp     @begin_up
@S1:

        stx     history_entry_current_id

@begin_up:
       ;
        lda     next_current_position
        beq     @nothing_to_do

@go_up_entry:
        ldx     history_entry_current_id
        beq     @nothing_to_do


        dex
        stx     history_entry_current_id

        lda     history_buffer_ptr_low,x
        sta     RESB
        lda     history_buffer_ptr_high,x
        sta     RESB+1

        ldy     #shell_bash_struct::pos_command_line
        lda     (saveptr),y
        tax
        tay
        beq     @skip_clear_line
@clear_line:
        cputc	$08
        dey
        bne     @clear_line

        ; now fill with space
@clear_line2:
        cputc	' '
        dex
        bne     @clear_line2

@skip_clear_line:


        ldy     #$00
@L2:
        lda     (RESB),y
        beq     @eos_command
        sta     (saveptr),y
        iny
        bne     @L2
        lda     #$00
@eos_command:

        sta     (saveptr),y
        sty     savepos

        lda     #$0D
        BRK_TELEMON XWR0

	BRK_TELEMON XGETCWD
	BRK_TELEMON XWSTR0


        BRK_TELEMON XECRPR

        ldx     history_entry_current_id
        ldy     history_buffer_ptr_high,x
        lda     history_buffer_ptr_low,x

        BRK_TELEMON XWSTR0

        ldx     savepos

        lda     #$00
        ldy     history_entry_current_id
        rts

@nothing_to_do:
        lda     #$01
        rts
go_down_history_routine:
        rts

search_history:
        print reverse
@loop:
        cgetc	key
        cmp     #$03
        beq     ctrl_c
        jsr     search_history_key
        jmp     @loop

ctrl_c:
	asl	KBDCTC
	cputc	'^'
        cputc	'C'
        crlf
        lda     #$00
        rts

execute_command:
        ldx     savepos
        lda     #$01
        rts

search_history_key:
        ; A contains the key pressed

        ; we look from the bottom

        ldx     next_current_position
        ;stx
        ldy     next_current_position
        lda     history_buffer_ptr_low,y
        sta     RES
        lda     history_buffer_ptr_high,y
        sta     RES+1

        rts

key:
        .res 1

reverse:
        .byte $0D,"(search):",0

start:


        lda     #<history_buffer_command
        sta     history_buffer_ptr_low
        lda     #>history_buffer_command
        sta     history_buffer_ptr_high
        lda     #$00
        sta     next_current_position
        sta     history_entry_current_id
        print str_shellext_loaded
        print str_OK

        rts

str_shellext_loaded:
        .asciiz "Shell extentions "


register_command:
        sta     RES
        sty     RES+1

        ldy     next_current_position
        lda     history_buffer_ptr_low,y
        sta     RESB
        lda     history_buffer_ptr_high,y
        sta     RESB+1

        ldy     #$00
@L1:
        lda     (RES),y
        beq     @EOS
        sta     (RESB),y
        iny
        bne     @L1
        sta     (RESB),y
@EOS:
        sta     (RESB),y
        lda     next_current_position
        cmp     #HISTORY_MAX_NUMBER_ENTRY
        beq     @FIFO

        tax     ; Current_position
        lda     history_buffer_ptr_low,x
        inx
        sta     history_buffer_ptr_low,x
        dex
        lda     history_buffer_ptr_high,x
        inx
        sta     history_buffer_ptr_high,x

        inc     next_current_position
        inc     history_entry_current_id
        iny
        tya
        clc
        adc     history_buffer_ptr_low,x
        bcc     @do_not_inc
        inc     history_buffer_ptr_high,x
@do_not_inc:
        sta     history_buffer_ptr_low,x
@FIFO:

        rts
next_current_position:
        .byte 0
history_entry_current_id:
        .byte 0

history_buffer_ptr_low:
        .byte <history_buffer_command
        .res HISTORY_MAX_NUMBER_ENTRY-1
history_buffer_ptr_high:
        .byte >history_buffer_command
        .res HISTORY_MAX_NUMBER_ENTRY-1
history_buffer_command:
        .res    HISTORY_MAX_NUMBER_ENTRY*60


.code


rom_start:
        rts

rom_signature:
    .byte   "Shell extensions v"
    .ASCIIZ VERSION

_history:

        ldx     #$00
@L1:
        lda     history_buffer_ptr_low,x
        ldy     history_buffer_ptr_high,x
        stx     savex
        BRK_TELEMON XWSTR0
        crlf
        ldx     savex
        inx
        cpx     next_current_position
        bne     @L1
        rts

str_OK:
   .byte $82,"[OK]",$0D,0


command1_str:
        .asciiz "history"

commands_text:
        .addr command1_str
commands_address:
        .addr _history
commands_version:
        .ASCIIZ "0.0.1"



; ----------------------------------------------------------------------------
; Copyrights address
.res $FFED-*
magic_token_systemd:
        .byte "SET"

.byte $01
; $fff1
parse_vector:
        .byt $00,$00
; fff3
adress_commands:
        .addr commands_address
; fff5
list_commands:
        .addr command1_str
; $fff7
number_of_commands:
        .byt 1
signature_address:
        .word   rom_signature

; ----------------------------------------------------------------------------
; Version + ROM Type
ROMDEF:
        .addr rom_start

; ----------------------------------------------------------------------------
; RESET
rom_reset:
        .addr   rom_start
; ----------------------------------------------------------------------------
; IRQ Vector
empty_rom_irq_vector:
        .addr   IRQVECTOR ; from telestrat.inc (cc65)
end:
