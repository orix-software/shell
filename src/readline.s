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
.endif
;----------------------------------------------------------------------
;			readline includes
;----------------------------------------------------------------------
.include "dependencies/orix-sdk/macros/case.mac"

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

		; Vide le buffer?
		ldx	#$00
		BRK_KERNEL XVIDBU
		asl	KBDCTC

	loop:
;		cursor	on
		cgetc	key
;		cursor	off

	;touche précédente = esc?
	;	oui: touche actuelle = esc?
	;		oui: touche précédente = 0, loop
	;		non: touche précédente = 0, interprete esc+touche
	;	non: touche actuelle = esc?
	;		oui: touche précédente = esc, loop
	;		non: interprète touche

		; touche précédente = esc?
		lda	esc_flag
		beq	no_previous_esc

		; esc_key = 0
		lsr	esc_flag

		; touche actuelle = esc?
		lda	key
		cmp	#$1b
		beq	loop

	meta:
		; interprète esc+touche
		; Meta+b: move to the start of the current or previous word
		; Meta+f: move forward to the end of the next word (word: alphanum)
		; Meta+f: move to the end of the next word
		; Meta+l: lowercase   ''      ''        ''
		; Meta+u: uppercase the current (or following) word
		do_case	key
			case_of 'b', backward_word
			case_of 'f', forward_word
			case_of 'l', downcase_word
			case_of 'u', upcase_word
			otherwise meta_others
		end_case

		jmp	loop

	no_previous_esc:
		lda	key
		cmp	#$1b
		bne	normal

		; esc_key = 1
		rol	esc_flag
		jmp	loop

	; Mettre les combinaisons Funct+touche à part ou
	; dans normal?
;		cmp	#$80
;		bcc	normal
;	funct:
;		do_case key
;			case_of ...
;		end_case
;		jmp	loop

	normal:
		; Ctrl+a: Move to start of line
		; Ctrl+e: Move to end of line
		; Ctrl+f: Move forward a character
		; Ctrl+b: Move back a character
		; Ctrl+k: Kill the text from point to the end of the line
		; Ctrl+t: Transpose-chars
		; Ctrl+u: Kill all characters on the current line, no matter where point is.
		; Ctrl+x: Kill backward to the begining of the line
		; Ctrl+l: Clear screen, then redraw the current line, leavingthe current line at the top of the screen
		; Ctrl+o: Toggle overwrite mode
		do_case	key
			case_of $01, begining_of_line
			case_of $03, key_break
			case_of $05, end_of_line
			case_of $08, key_left
			case_of $09, key_right
			case_of $0a, key_down
			;case_of $0b, key_up
			case_of $0b, kill_line
			case_of $0c, clear_screen
			case_of $0d, key_enter
			; case_of $0e, key_ctrl_n
			case_of $0f, overwrite_mode
			case_of $14, transpose_chars
			case_of $15, kill_whole_line
			case_of $18, backward_kill_line
			case_of $7f, key_del

			case_of {' ', '}'}, key_normal

			; Touche de fonctions: >$80
			; Funct+0, Funct+9
			case_of {$80, $9a}, key_funct
			; case_of	$90, funct_0

			otherwise key_others
		end_case

		jmp	loop
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
.proc key_del
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

		; [<-]
		cputc	$08

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
		ldy	buffer_pos
	.ifdef RAM
		lda	buffer_ptr,y
	.else
		lda	(buffer_ptr),y
	.endif
		sta	CURSCR

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
;
; Variables:
;	Modifiées:
;		-
;	Utilisées:
;		-
; Sous-routines:
;	-
;----------------------------------------------------------------------
.proc key_normal
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
;
; Variables:
;	Modifiées:
;		-
;	Utilisées:
;		-
; Sous-routines:
;	-
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
;		ldy	KBDSHT	; $40: Fct, $80: Ctrl, $01: Shift
;		; jsr	PrintRegs
		rts
.endproc


;----------------------------------------------------------------------
; ctrl-keys.s
;----------------------------------------------------------------------

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
.proc begining_of_line
		ldy	buffer_pos
		beq	end

	loop:
		cputc	$08
		dey
		bne	loop

		sty	buffer_pos

		; Change le caractère sous le curseur
	.ifdef RAM
		lda	buffer_ptr
	.else
		lda	(buffer_ptr),y
	.endif
		sta	CURSCR

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
;
; Variables:
;	Modifiées:
;		-
;	Utilisées:
;		-
; Sous-routines:
;	-
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
		lda	#' '
		sta	CURSCR
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
.proc key_left
		; cputc

		ldy	buffer_pos
		beq	end_oups

		dec	buffer_pos
		cputc

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
;
; Variables:
;	Modifiées:
;		-
;	Utilisées:
;		-
; Sous-routines:
;	-
;----------------------------------------------------------------------
.proc key_right
		; cputc

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
		ldy	buffer_pos
	.ifdef RAM
		lda	buffer_ptr,y
	.else
		lda	(buffer_ptr),y
	.endif
		sta	CURSCR

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
.proc key_enter
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
;
; Variables:
;	Modifiées:
;		-
;	Utilisées:
;		-
; Sous-routines:
;	-
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
		lda	#' '
		sta	CURSCR
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
; kill end of line
; ROM: line_discard
.if 0
	.proc key_ctrl_n
			cputc
			ldy	buffer_pos
			beq	end
			lda	#' '
		loop:
			dey
			beq	end
		.ifdef RAM
			sta	buffer_ptr,y
		.else
			sta	(buffer_ptr),y
		.endif
			bne	loop
		end:
			rts

	.endproc
.endif

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
.proc overwrite_mode
		; Inverse b6
		lda	FLGSCR
		eor	#%01000000
		sta	FLGSCR

		; Correction bug curseur invisible
		; (passage clignotant -> fixe quand le curseur est éteint)
		and	#%01000000
		beq	end
		; [->]
		cputc	$09
		; [<-]
		cputc	$08
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
.proc transpose_chars
		; /!\ Attention: le kernel interprete Ctrl+t lors de la saisie
		; et pas seulement lors d'un affichage

		; set lowercase keyboard should be move in telemon bank
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
;		cputc	$08
;		cputc	$08
;		lda	buffer_ptr-1,y
;		pha
;		cputc
;		lda	buffer_ptr-2,y
;		sta	buffer_ptr-1,y
;		cputc
;		pla
;		sta	buffer_ptr-2,y
;		rts
		; Optimisation
		cputc	$08
		dec	buffer_pos
		dey

	swap:
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
; ROM: Ctrl+n
.proc kill_whole_line
		jsr	end_of_line
		lda	buffer_end
		sta	xpos
	loop:
		jsr	key_del
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
		lda	#' '
		sta	CURSCR

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
.proc  backward_kill_line
		; Kill backward to the beginning of the line
		; sauf que la rom efface la fin de la ligne
		; cputc

	loop:
		ldy	buffer_pos
		beq	end

		jsr	key_del
		jmp	loop

	end:
		rts
.endproc

;----------------------------------------------------------------------
; meta-keys.s
;----------------------------------------------------------------------
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
; Meta+b: move to the start of the current or previous word
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
;		cmp	#' '
;		bne	move
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
;		cmp	#' '
;		bne	move
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
;
; Variables:
;	Modifiées:
;		-
;	Utilisées:
;		-
; Sous-routines:
;	-
;----------------------------------------------------------------------
.proc forward_word
		ldy	buffer_pos
	loop:
	.ifdef RAM
		lda	buffer_ptr, y
	.else
		lda	(buffer_ptr),y
	.endif
		beq	end

;		cmp	#' '
;		bne	move
		jsr	is_alnum
		bcc	move

		cputc	$09
		iny
		bne	loop
		beq	end

	move:
	.ifdef RAM
		lda	buffer_ptr,y
	.else
		lda	(buffer_ptr),y
	.endif
		beq	end
;		cmp	#' '
;		beq	end
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
;
; Variables:
;	Modifiées:
;		-
;	Utilisées:
;		-
; Sous-routines:
;	-
;----------------------------------------------------------------------
.proc downcase_word
		ldy	buffer_pos
	loop:
	.ifdef RAM
		lda	buffer_ptr, y
	.else
		lda	(buffer_ptr),y
	.endif
		beq	end

		cmp	#' '
		bne	convert
		cputc
		iny
		bne	loop
		beq	end

	convert:
	.ifdef RAM
		lda	buffer_ptr,y
	.else
		lda	(buffer_ptr),y
	.endif
		beq	end
		cmp	#' '
		beq	end

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
;
; Variables:
;	Modifiées:
;		-
;	Utilisées:
;		-
; Sous-routines:
;	-
;----------------------------------------------------------------------
.proc upcase_word
		ldy	buffer_pos
	loop:
	.ifdef RAM
		lda	buffer_ptr, y
	.else
		lda	(buffer_ptr),y
	.endif
		beq	end

		cmp	#' '
		bne	convert
		cputc
		iny
		bne	loop
		beq	end

	convert:
	.ifdef RAM
		lda	buffer_ptr,y
	.else
		lda	(buffer_ptr),y
	.endif
		beq	end
		cmp	#' '
		beq	end

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
.proc key_funct
		jsr	_manage_shortcut

		; Retour au shell
		pla
		pla
		lda	#$00
		rts
.endproc

;----------------------------------------------------------------------
; utils.s
;----------------------------------------------------------------------

;----------------------------------------------------------------------
;
; Entrée:
;	A: code ASCII
;
; Sortie:
;	A,X,Y: inchangés
;	C=0: alpha numérique
;	C=1: pas alpha numérique
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
		; bit	out_sec+2		; out_sec+2: sec ($18)
		cmp	#$00			; N=1 si >= $80
		bpl	out
		bit	out			; SEV
		rts
.endproc

