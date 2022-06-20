;----------------------------------------------------------------------
; readline shell
;----------------------------------------------------------------------
.feature string_escapes

;----------------------------------------------------------------------
;                       cc65 includes
;----------------------------------------------------------------------
.ifdef STANDALONE
	.include "telestrat.inc"
.endif
.macpack longbranch

;----------------------------------------------------------------------
;			Orix Kernel includes
;----------------------------------------------------------------------
;.include "kernel/src/include/kernel.inc"

;----------------------------------------------------------------------
;			Orix SDK includes
;----------------------------------------------------------------------
.ifdef STANDALONE
	.include "macros/SDK.mac"
	.include "include/SDK.inc"
	.include "macros/types.mac"
	.include "macros/case.mac"
.else
	.include "dependencies/orix-sdk/macros/case.mac"
.endif

;----------------------------------------------------------------------
;				Imports
;----------------------------------------------------------------------

;----------------------------------------------------------------------
;				Exports
;----------------------------------------------------------------------
.ifdef RAM
	.export readline

	.export buffer_ptr
	.export buffer_pos
	.export buffer_end
.endif

;----------------------------------------------------------------------
; Defines / Constants
;----------------------------------------------------------------------
.macro disp_prompt
		; Displays current path
		BRK_KERNEL XGETCWD
		BRK_KERNEL XWSTR0

		; display prompt (# char)
           	 BRK_KERNEL XECRPR
		;lda	#'>'
		;lda	#']'
		;lda	#'$'
		;cputc
.endmacro

.enum
	CTRL_A = $01
	CTRL_B
	CTRL_C
	CTRL_D
	CTRL_E
	CTRL_F
	CTRL_G
	CTRL_H
	CTRL_I
	CTRL_J
	CTRL_K
	CTRL_L
	CTRL_M
	CTRL_N
	CTRL_O
	CTRL_P
	CTRL_Q
	CTRL_R
	CTRL_S
	CTRL_T
	CTRL_U
	CTRL_V
	CTRL_W
	CTRL_X
	CTRL_Y
	CTRL_Z
	CTRL_DEL = $1f
.endenum

; Définis dans src/dependencies/kernel/src/include/keyboard.inc
;KEY_LEFT = $08
;KEY_RIGHT = $09
;KEY_DOWN = $0a
;KEY_UP = $0b
;KEY_RETURN = $0d
;KEY_ESC = $1b
;KEY_DEL = $7f

;----------------------------------------------------------------------
;				Variables
;----------------------------------------------------------------------
;.segment "DATA"
;	unsigned char buffer_ptr[256]
	.define buffer_ptr bash_struct_ptr

	.define buffer_pos bash_tmp1
	.define buffer_end sh_length_of_command_line
	.define buffer_max BASH_MAX_LENGTH_COMMAND_LINE

	.define key bash_tmp1+1
	.define esc_flag sh_esc_pressed

	;unsigned short prompt_ptr

	.define work ptr1_for_internal_command
	.define xpos sh_ptr1

;----------------------------------------------------------------------
;
;----------------------------------------------------------------------

;----------------------------------------------------------------------
;
; Entrée:
;	AY: adresse prompt
;	X : logueur maximale de la ligne
; Sortie:
;
; Variables:
;	Modifiées:
;		-
;	Utilisées:
;		-
; Sous-routines:
;	-
;----------------------------------------------------------------------
.proc readline

	;----------------------------------------------------------------------
	; Display prompt
	;----------------------------------------------------------------------
	.ifdef RAM
		sta	prompt_ptr
		sty	prompt_ptr+1
		stx	buffer_max

		; Affiche le prompt
		;.byte	$00, XECRPR
		eor	prompt_ptr+1
		beq	init_vars
		print	(prompt_ptr)
	.else
		; Displays current path
		disp_prompt           ; display prompt (# char)
	.endif

	;----------------------------------------------------------------------
	; Init vars
	;----------------------------------------------------------------------
	init_vars:
		lda	#$00
		sta	esc_flag

		; 1=insert, 0=overwrite
		; b7: curseur off/on, b6: curseur clignotant/fixe
;		lda	FLGSCR
;		and	#%10111111
;		sta	FLGSCR

		; Initialise les pointeurs sinon un second appel
		; à readline reprend les valeurs précédentes
		; (pas d'affacement du buffer)
		;
		; TODO? Voir si readline doit faire un malloc de buffer_ptr
		; à chaque appel et renvoyé son adresse en sortie
		sta	buffer_pos
		sta	buffer_end
		tay
	.ifdef RAM
		sta	buffer_ptr,y
	.else
		sta	(buffer_ptr),y
	.endif

		; Vide le buffer
		ldx	#$00
		BRK_KERNEL XVIDBU

		; Annule le flag CTRL+C
		asl	KBDCTC

	;----------------------------------------------------------------------
	; Main loop
	;----------------------------------------------------------------------
	loop:
		cgetc	key

.if 1
		; 17 octets (11 cycles pour une touche normale)
		; Conserve A
		cmp	#KEY_ESC		; [2]
		bne	suite			; [2/3]
		lda	esc_flag		; [3]
		eor	#%10000000		; [2]
		sta	esc_flag		; [3]
		jmp	loop			; [3]

	suite:
		bit	esc_flag			; [3]
		bpl	normal			; [2/3]

.else
		; 22 octets (14 cycles pour une touche normale +2 avec tax)
		; Permet d'économiser 1 octet en page 0 (réutilisation de FLGSCR)
		; Détruit A
		cmp	#KEY_ESC		; [2]
		bne	suite			; [2/3]

		lda	FLGSCR			; [4]
		eor	#%00001000		; [2]
		sta	FLGSCR			; [4]
		jmp	loop			; [3]

	suite:
		;tax				; [2]
		lda	FLGSCR			; [4]
		and	#%00001000		; [2]
		beq	normal			; [2/3]

.endif

	;----------------------------------------------------------------------
	; [Esc]+...
	;----------------------------------------------------------------------
	meta:
		;KBDSHT: b7: Ctrl, b6: Funct,  b1: Shift
;		bit	KBDSHT
;		bmi	meta_ctrl_keys
;		jvs	meta_funct_keys

		; interprète esc+touche
		; Meta+b: Move to the start of the current or previous word
		; Meta+f: Move forward to the end of the next word (word: alphanum)
		; Meta+f: Move to the end of the next word
		; Meta+l: Lowercase   ''      ''        ''
		; Meta+u: Uppercase the current (or following) word
		; Meta+c: Capitalize the current (or following) word
		; Meta+d: Kill from point to the end of the current word,
		;         or if between words, to the end of the next word.
		; Meta+Del: Kill the word behind point
		; Meta+t: Transpose-chars
		do_case	key
			case_of 'b', backward_word
			case_of 'f', forward_word
			case_of 'l', downcase_word
			case_of 'u', upcase_word
			case_of 'c', capitalize_word
			case_of	'd', kill_word
			case_of KEY_DEL, backward_kill_word

			; Spécifique Orix
			; Normalement M-t: transpose-words
			case_of 't', transpose_chars

			otherwise meta_others
		end_case
		jmp	loop

	;----------------------------------------------------------------------
	; [Esc]+[Ctrl]+<touche>
	;----------------------------------------------------------------------
;	meta_ctrl_keys:
;		do_case	key
;			case_of
;			otherwise meta_ctrl_others
;		end_case
;		jmp	loop

	;----------------------------------------------------------------------
	; [Esc]+[Funct]+<touche>
	;----------------------------------------------------------------------
;	meta_funct_keys:
;		do_case	key
;			case_of
;			otherwise meta_funct_others
;		end_case
;		jmp	loop

	;----------------------------------------------------------------------
	; Normal
	;----------------------------------------------------------------------
	normal:
		;KBDSHT: b7: Ctrl, b6: Funct,  b1: Shift
		bit	KBDSHT
		bmi	ctrl_keys
		jvs	funct_keys

		; (key < $20) or (key == $7f) => cursor
		cmp	#$20
		bcc	normal_cursor
		cmp	#KEY_DEL
		beq	normal_cursor
		jsr	self_insert
		jmp	loop

	;----------------------------------------------------------------------
	; Cursor
	;----------------------------------------------------------------------
	normal_cursor:
		lda	KBDSHT
		lsr
		bcs	with_shift

		; [<-]: Move backward a character
		; [->]: Move forward a character
		; [Return]: Accept line
		; [Del]: Delete the character behind the cursor
		do_case	key
			case_of KEY_LEFT, backward_char
			case_of KEY_RIGHT, forward_char
			case_of KEY_RETURN, accept_line
			case_of KEY_DEL, backward_delete_char
;			case_of {' ', '}'}, self_insert
			otherwise key_others
		end_case
		jmp	loop

	;----------------------------------------------------------------------
	; [Shift]+<cursor> (spécifique Orix)
	;----------------------------------------------------------------------
	with_shift:
		; [Shift]+[<-]: Move to start of line
		; [Shift]+[->]: Move to end of line
		; [Shift]+[Del]: Delete the character at point
		do_case	key
			case_of KEY_LEFT, beginning_of_line
			case_of KEY_RIGHT, end_of_line
			case_of KEY_DEL, delete_char
;			case_of {' ', '}'}, self_insert
			otherwise key_others
		end_case
		jmp	loop

	;----------------------------------------------------------------------
	; [Ctrl]+...
	;----------------------------------------------------------------------
	ctrl_keys:
;		lda	KBDSHT
;		lsr
;		bcs	ctrl_shift

		; Ctrl+a: Move to start of line
		; Ctrl+e: Move to end of line
		; Ctrl+c: Break
		; Ctrl+l: Clear screen, then redraw the current line, leavingthe current line at the top of the screen
		; Ctrl+x: Kill the text from point to the end of the line
		; Ctrl+n: Kill all characters on the current line, no matter where point is.
		; Ctrl+del: Kill backward to the beginning of the line
		; Ctrl+h: Move back to the start of the current or previous word.
		; Ctrl+i: Move forward to the end of the next word.
		; Ctrl+o: Toggle overwrite mode
		do_case	key
			case_of CTRL_A, beginning_of_line
			case_of CTRL_E, end_of_line

			case_of CTRL_C, key_break
			case_of CTRL_L, clear_screen

			; Compatibilité Telestrat
			case_of	CTRL_X, kill_line
			case_of	CTRL_N, kill_whole_line
			case_of	CTRL_DEL, backward_kill_line

			; Spécifique Orix
;			case_of	CTRL_H, backward_word
;			case_of	CTRL_I, forward_word

			; Ctrl+D: delete-char si ligne vide, sinon EOF
;			case_of CTRL_D, delete_char
;			case_of CTRL_K, kill_line
;			case_of CTRL_U, kill_whole_line
;			case_of CTRL_X, backward_kill_line
;			case_of	CTRL_DEL, forward_backward_delete_char
;			case_of CTRL_H, backward_delete_char
;			case_of CTRL_I, complete
;			case_of CTRL_N, next_history

			case_of CTRL_O, overwrite_mode
;			case_of CTRL_T, transpose_chars
			otherwise ctrl_key_others
		end_case
		jmp	loop

	;----------------------------------------------------------------------
	; [Ctrl]+[Shift]+<touche>
	;----------------------------------------------------------------------
;	ctrl_shift:
;		do_case	key
;			case_of CTRL_...
;		end_case
;		jmp	loop

	;----------------------------------------------------------------------
	; [Funct]+...
	;----------------------------------------------------------------------
;		lda	KBDSHT
;		lsr
;		bcs	funct_shift
	funct_keys:
		do_case	key
			; Touche de fonctions: >$80
			; Funct+A, Funct+Z
			case_of {$81, $9a}, key_funct
			otherwise funct_key_others
		end_case
		jmp	loop

	;----------------------------------------------------------------------
	; [Funct]+[Shift]+<touche>
	;----------------------------------------------------------------------
;	funct_shift:
;		do_case	key
;			case_of ...
;		end_case
;		jmp	loop
.endproc


;======================================================================
;			Exit functions
;======================================================================

;----------------------------------------------------------------------
;
; Entrée:
;	A: buffer_end
;	Y: Modifié
; Sortie:
;
; Variables:
;	Modifiées:
;		- buffer_ptr
;	Utilisées:
;		- buffer_pos
;		- buffer_end
; Sous-routines:
;	- crlf
;----------------------------------------------------------------------
.proc accept_line
;		lda	#$00
;		sta	buffer_pos
;		sta	buffer_end
;		sta	buffer_ptr

		crlf

		; Retour au programme principal
		pla
		pla

	.ifndef RAM
		; Compatibilité version originale de shell
		; A supprimer?
		lda	buffer_pos
		ldy	#shell_bash_struct::pos_command_line
		sta	(buffer_ptr),y
	.endif

		; buffer length
		lda	buffer_end
		rts
.endproc


;----------------------------------------------------------------------
;
; Entrée:
;
; Sortie:
;	A: 0
;	Y: Modifié
; Variables:
;	Modifiées:
;		- buffer_pos
;		- buffer_end
;		- buffer_ptr
;	Utilisées:
;		-
; Sous-routines:
;	- cputc
;	- crlf
;----------------------------------------------------------------------
.proc key_break
		lda	#$00
		sta	buffer_pos
		sta	buffer_end

	.ifdef RAM
		sta	buffer_ptr
	.else
		tay
		sta	(buffer_ptr),y
	.endif

		asl	KBDCTC

		cputc	'^'
		cputc	'C'
		crlf

		; Oublie l'adresse de l'appelant (readline) pour retour
		; direct au niveau supérieur (start_sh_interactive)
		pla
		pla

		; buffer length: 0
		; lda	buffer_end	; [4]
		lda	#$00		; [2]

	.ifndef RAM
		; Compatibilité version originale de shell
		; A supprimer?
		ldy	#shell_bash_struct::pos_command_line
		sta	(buffer_ptr),y

		; Pour le flag Z
		lda	#$00
	.endif

		rts
.endproc


;----------------------------------------------------------------------
;
; Entrée:
;
; Sortie:
;	A: 0
;	Y: Modifié
; Variables:
;	Modifiées:
;		-
;	Utilisées:
;		- buffer_end
; Sous-routines:
;	- _manage_shortcut
;----------------------------------------------------------------------
.proc key_funct
		; Utilisable uniquement si la ligne de commande est vide
		ldy	buffer_end
		bne	end_oups

		; Retour au shell uniquement si _manage_shortcut
		; s'est bien passé
		jsr	_manage_shortcut
		bne	end_oups

		; Retour au shell
		pla
		pla
		lda	#$00
	end_oups:
		rts
;	end_oups:
;		oups
;		rts

	; Retour systématique au shell avec le code de retour de _manage_shortcut
	; Dans ce cas si le raccourci ne fonctionne pas, le shell tente
	; d'exécuter la ligne de commande
;		jsr	_manage_shortcut
;		tax
;		pla
;		pla
;		txa
;		rts

	; Retour systématique au shell en forçant un code Ok
;		jsr	_manage_shortcut
;		pla
;		pla
;		lda	#$00
;		rts
.endproc


;======================================================================
;			Commands for moving
;======================================================================

;----------------------------------------------------------------------
;
; Entrée:
;
; Sortie:
;	C: 0->Ok, 1->EOF
;	A: Premier caractère du mot ou 0
;	Y: Position dans le buffer
; Variables:
;	Modifiées:
;		- buffer_pos
;	Utilisées:
;		- buffer_pts
; Sous-routines:
;	- cputc
;----------------------------------------------------------------------
.proc _word_begin
		ldy	buffer_pos

	loop:
	.ifdef RAM
		lda	buffer_ptr, y
	.else
		lda	(buffer_ptr),y
	.endif
		beq	end_oups

		jsr	is_alnum
		bcc	end

		cputc	$09
		iny
		bne	loop

	end_oups:
		sec

	end:
		sty	buffer_pos
		rts
.endproc

;----------------------------------------------------------------------
;
; Entrée:
;
; Sortie:
;	A,Y: Modifiés
; Variables:
;	Modifiées:
;		- buffer_pos
;	Utilisées:
;		-
; Sous-routines:
;	- cputc
;----------------------------------------------------------------------
.proc backward_char
		ldy	buffer_pos
		beq	end_oups

		dec	buffer_pos
		; [<-]
		cputc	$08

	end:
		rts

	end_oups:
		oups
		rts
.endproc

;----------------------------------------------------------------------
;
; Entrée:
;
; Sortie:
;	A,Y: Modifiés
; Variables:
;	Modifiées:
;		- buffer_pos
;	Utilisées:
;		- buffer_ptr
; Sous-routines:
;	- cputc
;----------------------------------------------------------------------
.proc forward_char
		ldy	buffer_pos

	.ifdef RAM
		lda	buffer_ptr,y
	.else
		lda	(buffer_ptr),y
	.endif
		beq	end_oups

		inc	buffer_pos
		; [->]
		cputc	$09

	end:
		rts

	end_oups:
		oups
		rts
.endproc

;----------------------------------------------------------------------
;
; Entrée:
;
; Sortie:
;	A,Y: Modifiés
; Variables:
;	Modifiées:
;		- buffer_pos
;	Utilisées:
;		-
; Sous-routines:
;	- cputc
;----------------------------------------------------------------------
.proc beginning_of_line
		ldy	buffer_pos
		beq	end

	loop:
		cputc	$08
		dey
		bne	loop

		sty	buffer_pos

		; Change le caractère sous le curseur
;	.ifdef RAM
;		lda	buffer_ptr
;	.else
;		lda	(buffer_ptr),y
;	.endif
;		sta	CURSCR

	end:
		rts
.endproc

;----------------------------------------------------------------------
;
; Entrée:
;
; Sortie:
;	A: Modifié
;	X: 0
; Variables:
;	Modifiées:
;		- buffer_pos
;	Utilisées:
;		- buffer_end
; Sous-routines:
;	- cputc
;----------------------------------------------------------------------
.proc end_of_line
		sec
		lda	buffer_end
		sbc	buffer_pos
		beq	end
		tax
	loop:
		; [->]
		cputc	$09
		dex
		bne	loop

	ok:
		lda	buffer_end
		sta	buffer_pos

		; Change le caractère sous le curseur
;		lda	#' '
;		sta	CURSCR
	end:
		rts
.endproc

;----------------------------------------------------------------------
;
; Entrée:
;
; Sortie:
;	A,Y: Modifiés
; Variables:
;	Modifiées:
;		- buffer_pos
;		- buffer_ptr
;	Utilisées:
;		-
; Sous-routines:
;	- is_alnum
;	- cputc
;----------------------------------------------------------------------
; Move to the start of the current or previous word
.proc backward_word
		ldy	buffer_pos
		beq	end

	loop:
		dey
	.ifdef RAM
		lda	buffer_ptr,y
	.else
		lda	(buffer_ptr),y
	.endif
		jsr	is_alnum
		bcc	move

		cputc	$08
		bne	loop

	move:
		cputc	$08
		dey
		bne	backward
		cputc	$08
		jmp	end

	backward:
		beq	end
	.ifdef RAM
		lda	buffer_ptr,y
	.else
		lda	(buffer_ptr),y
	.endif
		jsr	is_alnum
		bcc	move
		iny
	end:
		sty	buffer_pos
		rts
.endproc

;----------------------------------------------------------------------
;
; Entrée:
;
; Sortie:
;	A: Modifié
;	Y: Modifié
; Variables:
;	Modifiées:
;		- buffer_pos
;		- buffer_ptr
;	Utilisées:
;		-
; Sous-routines:
;	- is_alnum
;	- cputc
;----------------------------------------------------------------------
.proc forward_word
		jsr	_word_begin
		bcs	end
	move:
	.ifdef RAM
		lda	buffer_ptr,y
	.else
		lda	(buffer_ptr),y
	.endif
		beq	end

		jsr	is_alnum
		bcs	end

		cputc	$09
		iny
		bne	move

	end:
		sty	buffer_pos
		rts
.endproc

;----------------------------------------------------------------------
;
; Entrée:
;
; Sortie:
;	A: Modifié
;	X: 0
; Variables:
;	Modifiées:
;		-
;	Utilisées:
;		- buffer_pos
;		- buffer_end
; Sous-routines:
;	- print
;----------------------------------------------------------------------
.proc clear_screen
		cputc

	.ifdef RAM
		print	(prompt_ptr)
		print	buffer_ptr
	.else
		; Displays current path
		disp_prompt           ; display prompt (# char)

		print	(buffer_ptr)
	.endif

		sec
		lda	buffer_end
		sbc	buffer_pos
		beq	end
		tax
	loop:
		; [<-]
		cputc	$08
		dex
		bne	loop

	ok:
		; Change le caractère sous le curseur
;		ldy	buffer_pos
;	.ifdef RAM
;		lda	buffer_ptr,y
;	.else
;		lda	(buffer_ptr),y
;	.endif
;		sta	CURSCR

	end:
		rts
.endproc

;----------------------------------------------------------------------
;
; Entrée:
;
; Sortie:
;
; Variables:
;	Modifiées:
;		-
;	Utilisées:
;		-
; Sous-routines:
;	-
;----------------------------------------------------------------------
.proc key_down
		rts
.endproc

;----------------------------------------------------------------------
;
; Entrée:
;
; Sortie:
;
; Variables:
;	Modifiées:
;		-
;	Utilisées:
;		-
; Sous-routines:
;	-
;----------------------------------------------------------------------
.proc key_up
		rts
.endproc


;======================================================================
;			Commands for changing text
;======================================================================

;----------------------------------------------------------------------
;
; Entrée:
;
; Sortie:
;
; Variables:
;	Modifiées:
;		-
;	Utilisées:
;		-
; Sous-routines:
;	-
;----------------------------------------------------------------------
.proc backward_delete_char
	ok:
		lda	buffer_pos
		beq	end_oups

		; Si on est sur le dernier caractère, on peut se contenter
		; de [<-] [ ] [<-]
		; sinon il faut [<-] [afficher la fin de la ligne] [ ] et remettre
		; le curseur à sa place
;		cputc	$08
;		cputc	' '
;		cputc	$08

		; décaler le buffer de buffer+buffer_pos à buffer+buffer_end vers buffer-1+buffer_pos
		ldy	buffer_pos
	loop:
	.ifdef RAM
		lda	buffer_ptr,y
		sta	buffer_ptr-1,y
	.else
		lda	(buffer_ptr),y
		dey
		sta	(buffer_ptr),y
		iny
	.endif
		iny
		cpy	buffer_end
		bcc	loop

		lda	#$00
	.ifdef RAM
		sta	buffer_ptr-1,y
	.else
		dey
		sta	(buffer_ptr),y
		iny
	.endif
		dec	buffer_pos
		dec	buffer_end

		ldy	buffer_pos
		cpy	buffer_end
		beq	eol

		; Si le curseur était au début de la ligne on l'y laisse
		; (possible uniquement si on vient de delete_char)
		cpy	#$ff
		bne	cursor_left
		inc	buffer_pos
		beq	display_buffer

	cursor_left:
		; [<-]
		cputc	$08

	display_buffer:
		; Sauvegarde la position du curseur
;		lda	SCRX
;		pha
;		lda	SCRY
;		pha

		; Affiche la fin du tampon + un espace
		clc
	.ifdef RAM
		lda	#<buffer_ptr
		adc	buffer_pos
		sta	work
		lda	#>buffer_ptr
	.else
		lda	buffer_ptr
		adc	buffer_pos
		sta	work
		lda	buffer_ptr+1
	.endif
		adc	#$00
		sta	work+1
		print	(work)
		cputc	' '

		; Replace le curseur au bon endroit
;		pla
;		sta	SCRY
;		pla
;		sta	SCRX
		sec
		lda	buffer_end
		sbc	buffer_pos
		tax
	backward:
		; [<-]
		cputc	$08
		dex
		bpl	backward

		; Change le caractère sous le curseur
;		ldy	buffer_pos
;	.ifdef RAM
;		lda	buffer_ptr,y
;	.else
;		lda	(buffer_ptr),y
;	.endif
;		sta	CURSCR

	end:
		rts

	eol:
		; [<-] ' ' [<-]
		cputc	$08
		cputc	' '
		cputc	$08
		rts

	end_oups:
		oups
		rts
.endproc

;----------------------------------------------------------------------
;
; Entrée:
;
; Sortie:
;	Y: Modifié
; Variables:
;	Modifiées:
;		-
;	Utilisées:
;		- buffer_pos
;		- buffer_end
; Sous-routines:
;	- delete_char
;	- backward_delete_char
;----------------------------------------------------------------------
.ifref forward_backward_delete_char
	.proc forward_backward_delete_char
			; Delete the character under the cursor, unless the cursor
			; is at the end of the line, in which case the character
			; behind the cursor is deleted.
			ldy	buffer_pos
			cpy	buffer_end
			bne	delete_char
			jmp	backward_delete_char
	.endproc
.endif

;----------------------------------------------------------------------
;
; Entrée:
;
; Sortie:
;	Y: Modifié
; Variables:
;	Modifiées:
;		- buffer_pos
;	Utilisées:
;		-
; Sous-routines:
;	- backward_delete_char
;	- cputc
;	- oups
;----------------------------------------------------------------------
.proc delete_char
		ldy	buffer_pos
		php
		cpy	buffer_end
		beq	end_oups

		iny
		jsr	backward_delete_char::loop
		plp
		beq	end

		; Remet le curseur à sa place
		; [->]
		cputc	$09
		inc	buffer_pos

		; Change le caractère sous le curseur
;		ldy	buffer_pos
;	.ifdef RAM
;		lda	buffer_ptr,y
;	.else
;		lda	(buffer_ptr),y
;	.endif
;		sta	CURSCR

	end:
		rts

	end_oups:
		plp
		oups
		rts
.endproc

;----------------------------------------------------------------------
;
; Entrée:
;
; Sortie:
;	A: 0
;	Y: Modifié
; Variables:
;	Modifiées:
;		- buffer_pos
;		- buffer_end
;		- buffer_ptr
;	Utilisées:
;		- buffer_max
; Sous-routines:
;	- insert
;	- ping
;	- cputc
;----------------------------------------------------------------------
.proc self_insert
		; Si le curseur est à la fin du buffer, on peut utiliser
		; overwrite quel que soit le flag overwrite_mode
		ldy	buffer_pos
		cpy	buffer_end
		beq	overwrite

		bit	FLGSCR
		bvs	overwrite
		jmp	insert

	overwrite:
		; Buffer plein?
	.ifdef RAM
		ldy	buffer_max
	.else
		ldy	#buffer_max
	.endif
		; dey pour tenir compte du fait que buffer_max indique un nombre
		; de caractères (l'index commence à 0 et non 1)
		dey
		cpy	buffer_pos
		beq	full

		pha
		cputc
		pla

		ldy	buffer_pos
	.ifdef RAM
		sta	buffer_ptr,y
	.else
		sta	(buffer_ptr),y
	.endif
		iny
		sty	buffer_pos

		cpy	buffer_end
		bcc	end

		sty	buffer_end
		lda	#$00

	.ifdef RAM
		sta	buffer_ptr,y
	.else
		sta	(buffer_ptr),y
	.endif

	end:
		rts

	full:
		; key_break rend la main au programme appelant,
		; voir si il faut le faire ou non si le buffer
		; est plein
		; cputc	'\'
		; jmp	key_break
		ping
		rts
.endproc

;----------------------------------------------------------------------
;
; Entrée:
;
; Sortie:
;	A: 0
;	Y: Modifié
; Variables:
;	Modifiées:
;		- buffer_end
;		- buffer_pos
;		- buffer_ptr
;	Utilisées:
;		- buffer_max
; Sous-routines:
;	- print
;	- ping
;	- cputc
;----------------------------------------------------------------------
.proc insert
		; Buffer plein?
	.ifdef RAM
		ldy	buffer_max
	.else
		ldy	#buffer_max
	.endif
		; dey pour tenir compte du fait que buffer_max indique un nombre
		; de caractères (l'index commence à 0 et non 1)
		dey
		cpy	buffer_end
		bne	_insert

		ping
		rts

	_insert:
		; Sauvegarde le caractère
		pha
		cputc

	.ifdef RAM
	.else
		; Affiche la fin de la ligne
		lda	buffer_ptr
		pha
		clc
		adc	buffer_pos
		sta	buffer_ptr
		lda	buffer_ptr+1
		pha
		adc	#$00
		sta	buffer_ptr+1

		print	(buffer_ptr)

		pla
		sta	buffer_ptr+1
		pla
		sta	buffer_ptr

		; Décalage du buffer vers la fin
		sec
		lda	buffer_end
		tay
		sbc	buffer_pos
		tax
	loop:
		lda	(buffer_ptr),y
		iny
		sta	(buffer_ptr),y

		; On en profite pour reculer le curseur
		; [<-]
		cputc	$08
		dey
		dey

		dex
		bpl	loop

		; Insère le caractère tapé
		; [->]
		cputc	$09
		pla
		iny
		sta	(buffer_ptr),y
	.endif

		inc	buffer_pos

		; Place un \0 à la fin du buffer
		inc	buffer_end
		ldy	buffer_end
		lda	#$00

	.ifdef RAM
		sta	buffer_ptr,y
	.else
		sta	(buffer_ptr),y
	.endif

	end:
		rts

.endproc

;----------------------------------------------------------------------
;
; Entrée:
;
; Sortie:
;	A,Y: Modifiés
; Variables:
;	Modifiées:
;		- FLGKBD
;		- buffer_pos
;		- buffer_ptr
;	Utilisées:
;		- buffer_end
; Sous-routines:
;	- cputc
;----------------------------------------------------------------------
.proc transpose_chars
		; /!\ Attention: le kernel interprete Ctrl+t lors de la saisie
		; et pas seulement lors d'un affichage

		; set lowercase keyboard
		lda	FLGKBD
		and	#%00111111 ; b7 : lowercase, b6 : no sound
		sta	FLGKBD

		; Echange le caractère sous le curseur avec le précédent
		; et se place sur le caractère suivant
		; Ne fait rien si on est sur le premier caractère
		; Echange les é caractères précédents si on est en fin
		; de ligne
		ldy	buffer_pos
		beq	end

		cpy	buffer_end
		bne	swap

		; Fin de ligne, il faut reculer de 2 caractères
		; [<-]
		cputc	$08
		dec	buffer_pos
		dey

	swap:
		; [<-]
		cputc	$08
	.ifdef RAM
		lda	buffer_ptr,y
	.else
		lda	(buffer_ptr),y
	.endif

		pha
		cputc

	.ifdef RAM
		lda	buffer_ptr-1,y
		sta	buffer_ptr,y
	.else
		dey
		lda	(buffer_ptr),y
		iny
		sta	(buffer_ptr),y
	.endif

		cputc
		pla

	.ifdef RAM
		sta	buffer_ptr-1,y
	.else
		dey
		sta	(buffer_ptr),y
		iny
	.endif

		; iny				; [2]
		; sty	buffer_pos		; [4]
		inc	buffer_pos		; [6]
	end:
		rts
.endproc

;----------------------------------------------------------------------
;
; Entrée:
;	A,Y:Modifiés
; Sortie:
;
; Variables:
;	Modifiées:
;		- buffer_pos
;		- buffer_ptr
;	Utilisées:
;		-
; Sous-routines:
;	- cputc
;----------------------------------------------------------------------
.proc downcase_word
		jsr	_word_begin
		bcs	end

	convert:
	.ifdef RAM
		lda	buffer_ptr,y
	.else
		lda	(buffer_ptr),y
	.endif
		; On peut supprimer le 'beq end' si on veut gagner 2 octets
		beq	end
		jsr	is_alnum
		bcs	end

		cmp	#'A'
		bcc	next
		cmp	#'Z'+1
		bcs	next
		eor	#'a'-'A'

	.ifdef RAM
		sta	buffer_ptr,y
	.else
		sta	(buffer_ptr),y
	.endif

	next:
		cputc
		iny
		bne	convert

	end:
		sty	buffer_pos
		rts
.endproc

;----------------------------------------------------------------------
;
; Entrée:
;
; Sortie:
;	A,Y:Modifiés
; Variables:
;	Modifiées:
;		- buffer_pos
;		- buffer_ptr
;	Utilisées:
;		-
; Sous-routines:
;	- cputc
;----------------------------------------------------------------------
.proc upcase_word
		jsr	_word_begin
		bcs	end

	convert:
	.ifdef RAM
		lda	buffer_ptr,y
	.else
		lda	(buffer_ptr),y
	.endif
		; On peut supprimer le 'beq end' si on veut gagner 2 octets
		beq	end
		jsr	is_alnum
		bcs	end

		cmp	#'a'
		bcc	next
		cmp	#'z'+1
		bcs	next
		eor	#'a'-'A'

	.ifdef RAM
		sta	buffer_ptr,y
	.else
		sta	(buffer_ptr),y
	.endif

	next:
		cputc
		iny
		bne	convert

	end:
		sty	buffer_pos
		rts
.endproc

;----------------------------------------------------------------------
;
; Entrée:
;
; Sortie:
;
; Variables:
;	Modifiées:
;		-
;	Utilisées:
;		-
; Sous-routines:
;	-
;----------------------------------------------------------------------
.proc capitalize_word
		jsr	_word_begin
		bcs	end

		cmp	#'a'
		bcc	forward
		cmp	#'z'+1
		bcs	forward
		eor	#'a'-'A'

	.ifdef RAM
		sta	buffer_ptr,y
	.else
		sta	(buffer_ptr),y
	.endif
		cputc
		iny

	forward:
		sty	buffer_pos
		jmp	forward_word

	end:
		sty	buffer_pos
		rts

	end_oups:
		oups
		rts
.endproc

;----------------------------------------------------------------------
;
; Entrée:
;	A: Modifié
; Sortie:
;
; Variables:
;	Modifiées:
;		- FLGSCR
;	Utilisées:
;		-
; Sous-routines:
;	- cputc
;----------------------------------------------------------------------
.proc overwrite_mode
		; Inverse b6
;		lda	FLGSCR
;		eor	#%01000000
;		sta	FLGSCR

		; Correction bug curseur invisible
		; (passage clignotant -> fixe quand le curseur est éteint)
;		and	#%01000000
;		beq	end

		; [->]
;		cputc	$09
		; [<-]
;		cputc	$08

		; Ctrl-P: Bascule curseur clignotant/fixe
		cputc	$10

	end:
		rts
.endproc


;======================================================================
;				Killing
;======================================================================

;----------------------------------------------------------------------
;
; Entrée:
;
; Sortie:
;	A: 0
;	X: 0
;	Y: Modifié
; Variables:
;	Modifiées:
;		- buffer_end
;		- buffer_ptr
;	Utilisées:
;		- buffer_pos
; Sous-routines:
;	- cputc
;----------------------------------------------------------------------
.proc kill_line
		; Clear to end of line
		sec
		lda	buffer_end
		sbc	buffer_pos
		beq	end
		pha
		tax
	loop:
		cputc	' '
		dex
		bne	loop

		pla
		tax
	backward:
		; [<-]
		cputc	$08
		dex
		bne	backward

		; Marque la fin du buffer
		txa
		ldy	buffer_pos
		sty	buffer_end

	.ifdef RAM
		sta	buffer_ptr,y
	.else
		sta	(buffer_ptr),y
	.endif

		; Change le caractère sous le curseur
;		lda	#' '
;		sta	CURSCR
	end:
		rts
.endproc

;----------------------------------------------------------------------
;
; Entrée:
;
; Sortie:
;
; Variables:
;	Modifiées:
;		-
;	Utilisées:
;		- buffer_pos
; Sous-routines:
;	- backward_delete_char
;----------------------------------------------------------------------
.proc backward_kill_line
		; Kill backward to the beginning of the line
		; sauf que la rom efface la fin de la ligne

	loop:
		ldy	buffer_pos
		beq	end

		jsr	backward_delete_char
		jmp	loop

	end:
		rts
.endproc

;----------------------------------------------------------------------
;
; Entrée:
;
; Sortie:
;	A: 0
;	Y: 0
;
; Variables:
;	Modifiées:
;		- buffer_end
;		- buffer_pos
;		- buffer_ptr
;		- xpos
;	Utilisées:
;		-
; Sous-routines:
;	- end_of_line
;	- backward_delete_char
;----------------------------------------------------------------------
; ROM: Ctrl+n
.proc kill_whole_line
		jsr	end_of_line
		lda	buffer_end
		sta	xpos
	loop:
		jsr	backward_delete_char
		dec	xpos
		bne	loop

		; Initialise le buffer
		lda	#$00
		sta	buffer_pos
		sta	buffer_end
		tay

	.ifdef RAM
		sta	buffer_ptr,y
	.else
		sta	(buffer_ptr),y
	.endif

		; Change le caractère sous le curseur
;		lda	#' '
;		sta	CURSCR

		rts
.endproc

;----------------------------------------------------------------------
;
; Entrée:
;
; Sortie:
;
; Variables:
;	Modifiées:
;		-
;	Utilisées:
;		-
; Sous-routines:
;	-
;----------------------------------------------------------------------
.proc kill_word

	loop:
		ldy	buffer_pos

	.ifdef RAM
		lda	buffer_ptr,y
	.else
		lda	(buffer_ptr),y
	.endif
		beq	end

		jsr	is_alnum
		bcc	loop2

		jsr	delete_char
		jmp	loop


	loop2:
		jsr	delete_char
		ldy	buffer_pos

	.ifdef RAM
		lda	buffer_ptr,y
	.else
		lda	(buffer_ptr),y
	.endif
		; beq	end
		jsr	is_alnum
		bcc	loop2

	end:
		rts
.endproc

;----------------------------------------------------------------------
;
; Entrée:
;
; Sortie:
;
; Variables:
;	Modifiées:
;		-
;	Utilisées:
;		-
; Sous-routines:
;	-
;----------------------------------------------------------------------
.proc backward_kill_word

	loop:
		ldy	buffer_pos
		beq	end
		dey

	.ifdef RAM
		lda	buffer_ptr,y
	.else
		lda	(buffer_ptr),y
	.endif
		; unix-word-rubout
		; cmp	#' '
		; bne	loop2
		; backward-kill-word
		jsr	is_alnum
		bcc	loop2

		jsr	backward_delete_char
		jmp	loop


	loop2:
		jsr	backward_delete_char
		ldy	buffer_pos
		beq	end
		dey

	.ifdef RAM
		lda	buffer_ptr,y
	.else
		lda	(buffer_ptr),y
	.endif
		; beq	end

		; unix-word-rubout
		; cmp	#' '
		; bne	loop2
		; backward-kill-word
		jsr	is_alnum
		bcc	loop2

	end:
		rts
.endproc


;======================================================================
;			Default cases
;======================================================================
;----------------------------------------------------------------------
;
; Entrée:
;
; Sortie:
;
; Variables:
;	Modifiées:
;		-
;	Utilisées:
;		-
; Sous-routines:
;	-
;----------------------------------------------------------------------
.proc key_others
;		cputc
;		lda	FLGKBD	; b7: MAJUSCULES/minuscules
;		ldx	KBDFCT
;		ldy	KBDSHT	; KBDSHT: b7: Ctrl, b6: Fct,  b1: Shift
;		jsr	PrintRegs

		;oups
		rts
.endproc

;----------------------------------------------------------------------
;
; Entrée:
;
; Sortie:
;
; Variables:
;	Modifiées:
;		-
;	Utilisées:
;		-
; Sous-routines:
;	-
;----------------------------------------------------------------------
.proc meta_others
		rts
.endproc

;----------------------------------------------------------------------
;
; Entrée:
;
; Sortie:
;
; Variables:
;	Modifiées:
;		-
;	Utilisées:
;		-
; Sous-routines:
;	-
;----------------------------------------------------------------------
.proc ctrl_key_others
		; oups
		; Place le curseur en X=10, Y=3
;		cputc	$1f
;		cputc	67
;		cputc	74
		;cputc	'*'
		rts
.endproc

;----------------------------------------------------------------------
;
; Entrée:
;
; Sortie:
;
; Variables:
;	Modifiées:
;		-
;	Utilisées:
;		-
; Sous-routines:
;	-
;----------------------------------------------------------------------
.proc funct_key_others
		; oups
		rts
.endproc

;======================================================================
;			Utilitaires
;======================================================================

;----------------------------------------------------------------------
;
; Entrée:
;	A: code ASCII
;
; Sortie:
;	A,X,Y: inchangés
;	C=0: alpha numérique
;		N=0: Alpha
;		N=1: Numérique
;	C=1: pas alpha numérique
;		N=0: Ponctuation ou > 'z'
;		N=1: Codes contrôle
;		V=1: Codes graphiques (>= $80)
;
; Variables:
;	Modifiées:
;		-
;	Utilisées:
;		-
; Sous-routines:
;	-
;----------------------------------------------------------------------
.proc is_alnum
		; Minuscules?
	min:
		cmp	#'z'+1
		bcs	out_cln		; Pb si A>=$fb => N=1
		cmp	#'a'

		; bcc	maj
		; oui
		; clc
		; rts
		; optimisation
		bcs	out_clc

		; Majuscules?
	maj:
		cmp	#'Z'+1
		bcs	out
		cmp	#'A'
		; bcc	num
		; ; oui
		; clc
		; rts
		; optimisation
		bcs	out_clc

		; Numérique?
	num:
		cmp	#'0'
		bcc	out_sec
		cmp	#'9'+1
		bcs	out
		; oui
		rts

	out_clc:
		clc
		rts

	out_sec:
		; Test pour codes contrôles ( < ' ')
		cmp	#' '
		sec
	out:
		rts

	out_cln:
		cmp	#$00			; N=1 si >= $80
		bpl	out
		bit	out			; SEV
		rts
.endproc

;======================================================================
;				E N D
;======================================================================
.out .sprintf("Readline size: %d", *-readline+1)

