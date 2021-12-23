IDEAL
P386
MODEL FLAT, C
ASSUME cs:_TEXT, ds:FLAT, es:FLAT, fs:FLAT, gs:FLAT

VMEMADR EQU 0A0000h	; video memory address
SCRWIDTH EQU 320	; screen witdth
SCRHEIGHT EQU 200	; screen height
FRAMESIZE EQU 256	; mario size (16x16)
KEYCNT EQU 89		; number of keys to track

CODESEG

INCLUDE "utils.inc"
INCLUDE "rect.inc"
INCLUDE "keyb.inc"

STRUC character
	x				dd 0		; x position
	y				dd 0		; y position
	speed_x			dd 0		; x speedcomponent
	speed_y			dd 0		; y speedcomponent
	w				dd 0		; width
	h 				dd 0		; height
	color 			dd 0		; color
	in_the_air		dd 0		; is mario currently in the air
	x_overlapping 	dd 0 		; 1 if mario is overlapping with a block in x coordinate, 0 otherwise
	y_overlapping 	dd 0		; 1 if mario is overlapping with a block in y coordinate, 0 otherwise
ENDS character

STRUC rect
	x	dd 0
	y	dd 0
	w	dd 0
	h	dd 0
ENDS rect

STRUC platform
	x 				dd 0		; x position
	y				dd 0		; y position
	w				dd 0		; width
	h				dd 0		; height
	color			dd 0		; color
ENDS platform

STRUC newPlatform
	x0		dd 0
	y0		dd 0
	x1		dd 0
	y1		dd 0
	d_x		dd 0 ; d_x & d_y should both be positive
	d_y		dd 0
	h		dd 0
	color	dd 0
ENDS newPlatform

STRUC barrel
	x				dd 0		; x position
	y				dd 0		; y position
	speed_x			dd 0		; x speedcomponent
	speed_y			dd 0		; y speedcomponent
	w				dd 0		; width
	h 				dd 0		; height
	color 			dd 0		; color
ENDS barrel

PROC checkCollision_new
	ARG @@x0: dword, @@y0: dword, @@x1: dword, @@y1: dword, @@h: dword RETURNS eax
	USES ebx
	
; x collision is hetz als vroeger
@@checkX:
	mov ebx, [mario.x]
	cmp ebx, 0					; checks for the left 
	jl @@outOfBounds				; edge of the screen
	
	add ebx, [mario.w]
	cmp ebx, 320				; checks for the right 
	jg @@outOfBounds				; edge of the screen
	
	mov eax, [@@x0]
	cmp eax, ebx			; checks for overlap 
	jge @@noXOverlap			; with blocks
	
	mov eax, [mario.x]
	mov ebx, [@@x1]
	cmp eax, ebx
	jge @@noXOverlap
@@xOverlap:
	mov [mario.x_overlapping], 1
	jmp @@checkY
@@noXOverlap:
	mov eax, 0
	ret
	
@@checkY:
	call collision_down, [mario.x], [mario.y], [mario.w], [mario.h], \
		[@@x0], [@@y0], [@@x1], [@@y1]
	cmp eax, 0
	je @@noYOverlap

; nog te implementeren -> collision_up	
;	mov eax, [mario.y]
;	mov ebx, [@@y0]
;	add ebx, [@@h]
;	cmp eax, ebx
;	jge noYOverlap
@@yOverlap:	
	mov [mario.y_overlapping], 1
	ret
@@noYOverlap:
	mov [mario.y_overlapping], 0
	mov [mario.x_overlapping], 0
	ret
@@outOfBounds:
	mov [mario.x_overlapping], 1
	
	ret	
ENDP checkCollision_new

PROC checkMarioCollision
	ARG @@ground: newPlatform
	USES eax, ebx
	
	; check for collision	
@@check:
;	call checkCollision, [ground1.x], [ground1.y], [ground1.w], [ground1.h]
	call checkCollision_new, [@@ground.x0], [@@ground.y0], [@@ground.x1], [@@ground.y1], [@@ground.h]
	cmp [mario.y_overlapping], 1
	jne @@nocol
	mov ebx, 0
	cmp [mario.speed_y], ebx
	jge @@bottom
@@top:
	mov [mario.speed_y], 0
	mov [mario.in_the_air], 0
	mov [mario.y_overlapping], 0
	jmp @@nocol
@@bottom:
	mov [mario.y_overlapping], 0
	mov [mario.y], eax 
	mov [mario.speed_y], 0
	mov [mario.in_the_air], 0
@@nocol:
	ret
ENDP checkMarioCollision

PROC checkCollision
	ARG @@n: dword
	LOCAL @@x0: dword, @@y0: dword, @@w: dword, @@h: dword
	USES eax, ebx
	
	cld

	; *20 omdat 5 eigenschappen per platform en 4 bytes per dword
	mov eax, [@@n]
	dec eax
	mov ebx, 20
	mul ebx
	mov eax, [offset platforms + eax]
	mov [@@x0], eax
	
	mov eax, [@@n]
	dec eax
	mov ebx, 20
	mul ebx
	mov eax, [offset platforms + eax + 4]
	mov [@@y0], eax
	
	mov eax, [@@n]
	dec eax
	mov ebx, 20
	mul ebx
	mov eax,  [offset platforms + eax + 8]
	mov [@@w], eax
	
	mov eax, [@@n]
	dec eax
	mov ebx, 20
	mul ebx
	mov eax, [offset platforms + eax + 12]
	mov [@@h], eax

checkX:
; de out-of-boundscheck zouden we hier niet moeten doen denk ik
	mov eax, [@@x0]
	mov ebx, [mario.x]
;	cmp ebx, 0					; checks for the left 
;	jl outOfBounds				; edge of the screen
	
	add ebx, [mario.w]
;	cmp ebx, 320				; checks for the right 
;	jg outOfBounds				; edge of the screen
	
	cmp eax, ebx			; checks for overlap 
	jge noXOverlap			; with blocks
	
	mov eax, [mario.x]
	mov ebx, [@@x0]
	add ebx, [@@w]
	cmp eax, ebx
	jge noXOverlap
xOverlap:
	mov [mario.x_overlapping], 1
	jmp checkY
noXOverlap:
	jmp endProcedure
checkY:
	mov eax, [@@y0]
	mov ebx, [mario.y]
	add ebx, [mario.h]
	cmp eax, ebx
	jge noYOverlap
	
	mov eax, [mario.y]
	mov ebx, [@@y0]
	add ebx, [@@h]
	cmp eax, ebx
	jge noYOverlap
yOverlap:	
	mov [mario.y_overlapping], 1
	jmp endProcedure
noYOverlap:
	mov [mario.y_overlapping], 0
	mov [mario.x_overlapping], 0
	jmp endProcedure
outOfBounds:
	mov [mario.x_overlapping], 1
endProcedure:	
	ret
ENDP checkCollision

PROC main
	sti
	cld
	
	push ds
	pop es
	
	call setVideoMode, 13h
	call __keyb_installKeyboardHandler
	
mainMenu:
	call fillRect,0,0,320,200,0h
	call drawRectangle,100,40,120,40,35h
	call displayString, 7, 16, offset msg1
	call displayString, 17, 18, offset msg2	
	call displayString, 19, 2, offset msgControlsLeft
	call displayString, 20, 2, offset msgControlsRight
	call displayString, 21, 2, offset msgControlsUp
	call displayString, 22, 2, offset msgControlsDown
	call displayString, 23, 2, offset msgControlsEnter
	
	push 1 ; using the stack, 1 is the top button and 2 the bottom one
	
menuloop:
	mov ebx, [offset __keyb_keyboardState + 11h] ;Z
	cmp ebx, 1
	je upmenu
	
	mov ebx, [offset __keyb_keyboardState + 1Fh] ;S
	cmp ebx, 1
	je downmenu
	jmp checkKeypresses
	
upmenu:
	pop ebx
	cmp ebx, 1
	je pushValue
	mov ebx, 1
	call drawRectangle,100,120,120,40,00h
	call drawRectangle,100,40,120,40,35h
	jmp pushValue
	
downmenu:
	pop ebx
	cmp ebx, 2
	je pushValue
	mov ebx, 2
	call drawRectangle,100,40,120,40,00h
	call drawRectangle,100,120,120,40,35h
	
pushValue:
	push ebx

checkKeypresses:
	mov ebx, [offset __keyb_keyboardState + 1Ch] ;Enter
	cmp ebx, 1
	jne checkEsc
	
	pop ebx
	cmp ebx, 2
	je exit
	
	jmp newgame ; jump to the main game loop
	
checkEsc:
	mov ebx, [offset __keyb_keyboardState + 01h] ;esc
	cmp ebx, 1
	jne menuloop
	
newgame:
	; (re-)initialise mario
	; mario character <40,60,0,0,16,20,33h,0,0,0>
	mov [mario.x], 40
	mov [mario.y], 60
	mov [mario.speed_x], 0
	mov [mario.speed_y], 0
	mov [mario.w], 16
	mov [mario.h], 20
	call fillRect, 0, 0, 320, 200, 0h
	call platformDown, [ground1.x0], [ground1.y0], [ground1.d_x], [ground1.d_y], [ground1.h], [ground1.color]
	call fillRect, [ground2.x], [ground2.y], [ground2.w], [ground2.h], [ground2.color]
	call fillRect, [ground3.x], [ground3.y], [ground3.w], [ground3.h], [ground3.color]
	call fillRect, [ground4.x], [ground4.y], [ground4.w], [ground4.h], [ground4.color]
	call fillRect, [mario.x], [mario.y], [mario.w], [mario.h], [mario.color]
	
mainloop:
	
	mov ebx, [offset __keyb_keyboardState + 01h] ;esc
	cmp ebx, 1
	je exit
	
	mov ebx, [offset __keyb_keyboardState + 1Eh] ;Q
	cmp ebx, 1
	jne noLeft
	; move left
;	call checkCollision, [ground1.x], [ground1.y], [ground1.w], [ground1.h]
	call checkCollision_new, [ground1.x0], [ground1.y0], [ground1.x1], [ground1.y1], [ground1.h]
	
	call checkCollision, 2
	call checkCollision, 3
	call checkCollision, 4
	
	mov [mario.y_overlapping], 0
	cmp [mario.x_overlapping], 1
	je noLeft
	mov ebx, [mario.x]
	cmp ebx, 4
	jge skipLeftBoundCheck
	mov [mario.x], 0
	jmp noLeft

skipLeftBoundCheck:
	mov [mario.x_overlapping], 0
;	sub [mario.x], 4
	mov [mario.speed_x], -4
	
noLeft:	
	mov [mario.x_overlapping], 0
	mov ebx, [offset __keyb_keyboardState + 20h] ;D
	cmp ebx, 1
	jne noRight
	add [mario.x], 4
;	call checkCollision, [ground1.x], [ground1.y], [ground1.w], [ground1.h]
	call checkCollision_new, [ground1.x0], [ground1.y0], [ground1.x1], [ground1.y1], [ground1.h]
	
	call checkCollision, 2
	call checkCollision, 3
	call checkCollision, 4
	
	mov [mario.y_overlapping], 0       
	sub [mario.x], 4
	cmp [mario.x_overlapping], 1
	je noRight
	mov ebx, [mario.x]
	add ebx, [mario.w]
	cmp ebx, SCRWIDTH-4
	jle skipRightBoundCheck
	mov [mario.x], 0
	jmp noRight

skipRightBoundCheck:
	mov [mario.x_overlapping], 0
;	add [mario.x], 4
	mov [mario.speed_x], 4
	
noRight:
	mov ebx, [mario.speed_y]
	or ebx, [mario.in_the_air] ; prevents from jumping again at the top of the arc
	cmp ebx, 0
	jne noUp
	
	mov ebx, [offset __keyb_keyboardState + 11h] ;Z
	cmp ebx, 1
	jne noUp	
	mov [mario.speed_y], -8
	mov [mario.in_the_air], 1
	
noUp:
	; check dat y niet > SCRHEIGHT
	mov eax, [mario.y]
	cmp eax, SCRHEIGHT
	jle @@noProblem
	jmp dead
	
@@noProblem:
	; draw and update mario
	mov eax, [mario.x]
	mov ebx, [mario.y]
	
	mov ecx, [mario.speed_x]
	add [mario.x], ecx
	mov edx, [mario.speed_y]
	add [mario.y], edx
	call fillRect, eax, ebx, [mario.w], [mario.h], [mario.color]
	
	call wait_VBLANK, 3
	
	; undraw mario
	call fillRect, eax, ebx, [mario.w], [mario.h], 0h	
	
	pop ecx
noJump:
	; gravity
	inc [mario.speed_y]
	
; check for collision
	call checkMarioCollision, [ground1.x0], [ground1.y0], [ground1.x1], [ground1.y1], [ground1.d_x], [ground1.d_y], [ground1.h], [ground1.color]
	cmp eax, -1
	je exit
	
check2:
	call checkCollision, 2
	cmp [mario.y_overlapping], 1
	jne check3
	mov ebx, 0
	cmp [mario.speed_y], ebx
	jle bottom2
top2:  ; if collision is with top of platform 2
	mov [mario.speed_y], 0
	mov [mario.in_the_air], 0
	mov [mario.y_overlapping], 0
	mov ebx, [ground2.y]
	sub ebx, [mario.h]
	mov [mario.y], ebx
	jmp check3
bottom2:
	mov [mario.y_overlapping], 0
	mov ebx, [ground2.y]
	add ebx, [ground2.h]
	mov [mario.y], ebx
	mov [mario.speed_y], 1
	
check3:
	call checkCollision, 3
	cmp [mario.y_overlapping], 1
	jne check4
	mov ebx, 0
	cmp [mario.speed_y], ebx
	jle bottom3
top3:
	mov [mario.speed_y], 0
	mov [mario.in_the_air], 0
	mov [mario.y_overlapping], 0
	mov ebx, [ground3.y]
	sub ebx, [mario.h]
	mov [mario.y], ebx
	jmp check4
bottom3:
	mov [mario.y_overlapping], 0
	mov ebx, [ground3.y]
	add ebx, [ground3.h]
	mov [mario.y], ebx
	mov [mario.speed_y], 1
	
check4:
	call checkCollision, 4
	cmp [mario.y_overlapping], 1
	jne noCollision
	mov ebx, 0
	cmp [mario.speed_y], ebx
	jle bottom4
top4:
	mov [mario.speed_y], 0
	mov [mario.in_the_air], 0
	mov [mario.y_overlapping], 0
	mov ebx, [ground4.y]
	sub ebx, [mario.h]
	mov [mario.y], ebx
	jmp noCollision
bottom4:
	mov [mario.y_overlapping], 0
	mov ebx, [ground4.y]
	add ebx, [ground4	.h]
	mov [mario.y], ebx
	mov [mario.speed_y], 1
	
noCollision:
	mov [mario.y_overlapping], 0
	
	; reset mario's speed_x
	mov [mario.speed_x], 0
	inc ecx
	jmp mainloop
	
dead:
	call wait_VBLANK, 30
	call fillRect, 0, 0, 320, 200, 0h
	call displayString, 7, 2, offset dead_message
	call wait_VBLANK, 90
	
	jmp mainMenu
exit:
	; exit on esc
	call __keyb_uninstallKeyboardHandler
	call terminateProcess
	ret
ENDP main	

DATASEG
	mario character <40,60,0,0,16,20,33h,0,0,0>
;	ground1 platform <0,190,320,10,25h>
	ground1 newPlatform <15, 180, 295, 185, 280, 5, 10, 25h>
	ground2 platform <240,160,40,5,25h>
	ground3 platform <180,140,40,5,25h>
	ground4 platform <120,115,40,5,25h>
	
	platforms 	dd 0,190,320,10,25h
				dd 240,160,40,5,25h
				dd 180,140,40,5,25h
				dd 120,115,40,5,25h

	openErrorMsg db "could not open file", 13, 10, '$'
	readErrorMsg db "could not read data", 13, 10, '$'
	closeErrorMsg db "error during file closing", 13, 10, '$'
	
	dead_message db "ded.",13,10,'$'

	msg1 	db "New Game", 13, 10, '$'
	msg2 	db "Exit", 13, 10, '$'
	msgControlsLeft		db "Q: LEFT", 13, 10, '$'
	msgControlsRight	db "D: RIGHT", 13, 10, '$'
	msgControlsUp		db "Z: UP/JUMP", 13, 10, '$'
	msgControlsDown		db "S: DOWN", 13, 10, '$'
	msgControlsEnter	db "ENTER: SELECT", 13, 10, '$'
	
	keybscancodes 	db 29h, 02h, 03h, 04h, 05h, 06h, 07h, 08h, 09h, 0Ah, 0Bh, 0Ch, 0Dh, 0Eh, 	52h, 47h, 49h, 	45h, 35h, 00h, 4Ah
					db 0Fh, 10h, 11h, 12h, 13h, 14h, 15h, 16h, 17h, 18h, 19h, 1Ah, 1Bh, 		53h, 4Fh, 51h, 	47h, 48h, 49h, 		1Ch, 4Eh
					db 3Ah, 1Eh, 1Fh, 20h, 21h, 22h, 23h, 24h, 25h, 26h, 27h, 28h, 2Bh,    						4Bh, 4Ch, 4Dh
					db 2Ah, 00h, 2Ch, 2Dh, 2Eh, 2Fh, 30h, 31h, 32h, 33h, 34h, 35h, 36h,  			 48h, 		4Fh, 50h, 51h,  1Ch
					db 1Dh, 0h, 38h,  				39h,  				0h, 0h, 0h, 1Dh,  		4Bh, 50h, 4Dh,  52h, 53h

UDATASEG;
	;filehandle dw ?
	;packedframe db FRAMESIZE dup (?)

	
STACK 100h

END main
