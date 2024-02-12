.export _lscpu

.proc _lscpu
    print   str_architecture
    jsr     _getcpu
    cmp     #CPU_65816
    beq     is65c816
    cmp     #CPU_65C02
    bne     is6502
    print   str_65C02
    jmp     next         ; FIXME 65c02

is65c816:
    print   str_65c816
    jmp     next

is6502:
    print   str_6502

next:
    crlf
    print   str_lscpu
    rts

str_65c816:
    .asciiz "65c816"

str_architecture:
    .asciiz "Architecture:   "

str_lscpu:
    .byte   "CPU op-mode(s): 8-bit",$0D,$0A ; or 16 bits if we detect a 65c816
    .byte   "Byte Order:     Little Endian",$0D,$0A
    .byte   "CPU(s):         1",$0D,$0A
    .byte   "Socket(s):      1",$0D,$0A
    .byte   "CPU MHz:        1",$0D,$0A,0
.endproc
