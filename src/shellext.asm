.define VERSION "2021.1"

.include   "telestrat.inc"
.include   "fcntl.inc"
.include   "build.inc"

userzp := $80 ; FIXME

.org $c000

.code
history_data:
   .res 1
history_data_strings:    
   .ASCIIZ "Hello"
   .res 1000
rom_start:
        rts

rom_signature:
    .byte   "Shell extensions v"
    .ASCIIZ VERSION

_history:
        lda #<history_data_strings
        ldy #>history_data_strings

        BRK_TELEMON XWSTR0
        rts

command1_str:
        .ASCIIZ "history"

commands_text:
        .addr command1_str
commands_address:
        .addr _history
commands_version:
        .ASCIIZ "0.0.1"


	
; ----------------------------------------------------------------------------
; Copyrights address

        .res $FFF1-*
        .org $FFF1
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
