IDEAL
MODEL small
STACK 100h
P386

CODESEG

include "fileio.asm"
include "keyboard.asm"
include "game.asm"
include "graphics.asm"
include "ui.asm"


start:
	mov ax, @data
	mov ds, ax

	; Install custom keyboard interrupt handler
	call instala_isr
	call clear_keyboard_flags

	;Check if debug mode is enabled ( -dbg flag)
	call CheckDebug
	cmp ax, 0
	je setVideoMode

	mov [byte ptr DebugBool], 1 ;set debug as true

setVideoMode:
	;Set text mode initially for menu:
	mov ax, 03h
	int 10h

	call PrintMainMenu

	;Set text mode back:
	mov ax, 03h
	int 10h

exit:
	; Restore original keyboard interrupt handler
	call desinstala_isr
	
	mov ax, 4c00h
	int 21h
END start