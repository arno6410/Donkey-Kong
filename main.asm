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
	x		dd 0		; x position
	y		dd 0		; y position
	speed_x	dd 0		; x speedcomponent
	speed_y	dd 0		; y speedcomponent
ENDS character

; draw Mario
PROC drawMario
	USES eax, ebx, ecx, edi	
	mov ecx, KEYCNT	; amount of keys to process
	
	call fillRect, [mario.x], [mario.y], 20, 30, 33h
	
@@loopkeys:	
	
	
	ret
ENDP drawMario

PROC main
	sti
	cld
	
	push ds
	pop es
	
	call setVideoMode, 13h
	call __keyb_installKeyboardHandler
	
	call fillRect, 0, 180, 320, 200, 25h
	call fillRect, [mario.x], [mario.y], 20, 30, 33h
	
mainloop:
	mov ebx, [offset __keyb_keyboardState + 4Dh] ;right
	shl ebx, 3
	jmp [jump_table + ebx]
	
uplbl:
	jmp endlbl
leftlbl: 	
	jmp endlbl	
rightlbl: 	
	call fillRect, [mario.x], 150, 20, 30, 0h
	mov eax, [mario.speed_x]
	add [mario.x], eax
	call fillRect, [mario.x], 150, 20, 30, 33h
	jmp endlbl		
endlbl:
	
	call wait_VBLANK, 3
	jmp mainloop
	
	; exit on esc
	call waitForSpecificKeystroke, 1Bh
	call __keyb_uninstallKeyboardHandler
	call terminateProcess
ENDP main	

DATASEG
	mario character <30,150,5,1>
	jump_table  dd uplbl, leftlbl, rightlbl, endlbl
	openErrorMsg db "could not open file", 13, 10, '$'
	readErrorMsg db "could not read data", 13, 10, '$'
	closeErrorMsg db "error during file closing", 13, 10, '$'
	
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