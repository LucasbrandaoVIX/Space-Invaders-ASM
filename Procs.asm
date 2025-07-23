CODESEG
include "Macros.asm"

; ---------------------------------------------------------------------------------------
; Filling the entire screen (graphic mode 320x200) with black (standard palette, index 0)
; ---------------------------------------------------------------------------------------
proc ClearScreen
	push ax cx di es
	mov ax, 0A000h
	mov es, ax

	xor di, di
	mov cx, 320*200/2
	xor ax, ax
	rep stosw

	pop es di cx ax

	ret
endp ClearScreen


; ----------------------------------------------------------------------
; Gets amount of ticks to wait (each tick is 1/18 of a second) from sack
; Creating a delay in the length it got
; ----------------------------------------------------------------------
proc Delay
	push bp
	mov bp, sp

	mov ax, 40h
	mov es, ax

	
	mov cx, [bp + 4]

	cmp cx, 0
	je @@procEnd

	mov ax, [es:6Ch]

@@delayLoop:
	cmp ax, [es:6Ch]
	je @@delayLoop

	mov ax, [es:6Ch]
	loop @@delayLoop

@@procEnd:
	pop bp
	ret 2
endp Delay


; ---------------------------------------------------------------------
; Get a number from stack
; Returns a 'Random' number in range 0 - (number - 1) to ax
; Using a randomized data file to eliminate timer-based random problems
; ---------------------------------------------------------------------
proc Random
	push bp
	mov bp, sp

	xor ax, ax

	cmp [word ptr bp + 4], 0
	je @@procEnd
	
; ---------------------------
; Stack State:
; | bp | bp + 2 |   bp + 4  |
; | bp |   sp   | maxNumber |
; ---------------------------
	
	push offset RandomFileName
	push offset RandomFileHandle
	call OpenFile

	;set file pointer:
	xor ah, ah
	int 1Ah

	xor cx, cx
	and dh, 00111111b

	mov ax, 4200h
	mov bx, [RandomFileHandle]
	int 21h
	jc @@planB ;in case of error

	mov bx, [RandomFileHandle]
	mov cx, 1
	mov dx, offset FileReadBuffer
	mov ah, 3Fh
	int 21h
	jc @@planBAndClose ;in case of error

	push [RandomFileHandle]
	call CloseFile

	mov al, [FileReadBuffer]
	xor ah, ah
	xor dx, dx
	mov bx, [bp + 4]
	div bx

	mov ax, dx

	jmp @@procEnd

@@planBAndClose:
	push [RandomFileHandle]
	call CloseFile

@@planB:
	;in case random operation fails
	;number was selected with a fair dice roll.
	mov ax, 6

	cmp [word ptr bp + 4], 6 ;make sure 6 is in range
	ja @@procEnd

	mov ax, 1

@@procEnd:
	pop bp
	ret 2
endp Random


; ---------------------------------------
; Check if the PSP is holding an argument
; and the argument is ' -dbg'
; If true, ax=1, else ax=0
; ---------------------------------------
proc CheckDebug
	mov ah, 2
	xor bh, bh
	xor dx, dx
	int 10h

	mov ah, 51h
	int 21h

	mov es, bx

	cmp [byte ptr es:80h], 5
	jne @@returnFalse

	cmp [word ptr es:81h], '- '
	jne @@returnFalse
	cmp [word ptr es:83h], 'bd'
	jne @@returnFalse
	cmp [byte ptr es:85h], 'g'
	jne @@returnFalse

	mov ax, 1
	ret


@@returnFalse:
	xor ax, ax
	ret
endp CheckDebug


; ---------------------------------------------------------
; Get a number from stack, return 4 decimal digits to dx:ax
; thousands in dh, hundreds in dl, tens in ah, units in al
; ---------------------------------------------------------
proc HexToDecimal
	push bp
	mov bp, sp

	mov ax, [bp + 4]

	mov cx, 4
@@findDigit:
	mov bl, 10
	div bl
	mov dx, ax
	shr dx, 8
	push dx
	xor ah, ah
	loop @@findDigit

	pop cx
	mov dh, cl
	pop cx
	mov dl, cl
	pop cx
	mov ah, cl
	pop cx
	mov al, cl

	;Convert to ASCII chars
	add dx, 3030h
	add ax, 3030h

	pop bp
	ret 2
endp HexToDecimal

; -----------------------------------------------
; Print a string at specific screen coordinates
; Parameters on stack: line, column, string offset
; -----------------------------------------------
proc PrintStringAt
	push bp
	mov bp, sp
	push ax bx cx dx si

	; Get parameters from stack
	mov dh, [bp + 8]  ; line
	mov dl, [bp + 6]  ; column
	mov si, [bp + 4]  ; string offset

	; Set cursor position
	mov ah, 02h
	mov bh, 0
	int 10h

	; Print string character by character
@@printLoop:
	mov al, [si]
	cmp al, '$'
	je @@endPrint
	
	; Print character
	mov ah, 0Eh
	mov bh, 0
	int 10h
	
	inc si
	jmp @@printLoop

@@endPrint:
	pop si dx cx bx ax
	pop bp
	ret 6
endp PrintStringAt

; -----------------------------------------------
; Print the difficulty selection menu
; -----------------------------------------------
proc PrintDifficultyMenu
	push ax bx cx dx

	; Clear screen using BIOS
	mov ah, 00h
	mov al, 03h  ; 80x25 color text mode
	int 10h

	; Print title
	push 5
	push 15
	push offset DifficultyTitleString
	call PrintStringAt

	; Print subtitle
	push 8
	push 12
	push offset SelectDifficultyString
	call PrintStringAt

	; Print options with highlighting
	call UpdateDifficultyMenuDisplay

	; Print instructions
	push 18
	push 5
	push offset UseArrowKeysString
	call PrintStringAt

	pop dx cx bx ax
	ret
endp PrintDifficultyMenu

; -----------------------------------------------
; Update the difficulty menu display with current selection
; -----------------------------------------------
proc UpdateDifficultyMenuDisplay
	push ax bx cx dx si

	; Clear the options area first
	mov cx, 3  ; Clear 3 lines
	mov dh, 12 ; Start at line 12
@@clearLoop:
	push cx
	push dx
	
	mov dl, 0  ; Column 0
	mov ah, 02h
	mov bh, 0
	int 10h
	
	mov cx, 80  ; Clear 80 characters
@@clearLineLoop:
	mov al, ' '
	mov ah, 0Eh
	int 10h
	loop @@clearLineLoop
	
	pop dx
	pop cx
	inc dh
	loop @@clearLoop

	; Now print options
	; Easy option
	mov al, [SelectedMenuItem]
	cmp al, 0
	jne @@printEasyNormal
	
	; Print highlighted Easy
	mov dh, 12
	mov dl, 16
	mov ah, 02h
	mov bh, 0
	int 10h
	
	mov al, '>'
	mov ah, 0Eh
	int 10h
	mov al, ' '
	mov ah, 0Eh
	int 10h
	
	mov si, offset EasyString
@@printEasyHighlight:
	mov al, [si]
	cmp al, '$'
	je @@endEasyHighlight
	mov ah, 0Eh
	int 10h
	inc si
	jmp @@printEasyHighlight
@@endEasyHighlight:
	mov al, ' '
	mov ah, 0Eh
	int 10h
	mov al, '<'
	mov ah, 0Eh
	int 10h
	jmp @@printMedium

@@printEasyNormal:
	push 12
	push 18
	push offset EasyString
	call PrintStringAt

@@printMedium:
	; Medium option
	mov al, [SelectedMenuItem]
	cmp al, 1
	jne @@printMediumNormal
	
	; Print highlighted Medium
	mov dh, 13
	mov dl, 15
	mov ah, 02h
	mov bh, 0
	int 10h
	
	mov al, '>'
	mov ah, 0Eh
	int 10h
	mov al, ' '
	mov ah, 0Eh
	int 10h
	
	mov si, offset MediumString
@@printMediumHighlight:
	mov al, [si]
	cmp al, '$'
	je @@endMediumHighlight
	mov ah, 0Eh
	int 10h
	inc si
	jmp @@printMediumHighlight
@@endMediumHighlight:
	mov al, ' '
	mov ah, 0Eh
	int 10h
	mov al, '<'
	mov ah, 0Eh
	int 10h
	jmp @@printHard

@@printMediumNormal:
	push 13
	push 17
	push offset MediumString
	call PrintStringAt

@@printHard:
	; Hard option
	mov al, [SelectedMenuItem]
	cmp al, 2
	jne @@printHardNormal
	
	; Print highlighted Hard
	mov dh, 14
	mov dl, 16
	mov ah, 02h
	mov bh, 0
	int 10h
	
	mov al, '>'
	mov ah, 0Eh
	int 10h
	mov al, ' '
	mov ah, 0Eh
	int 10h
	
	mov si, offset HardString
@@printHardHighlight:
	mov al, [si]
	cmp al, '$'
	je @@endHardHighlight
	mov ah, 0Eh
	int 10h
	inc si
	jmp @@printHardHighlight
@@endHardHighlight:
	mov al, ' '
	mov ah, 0Eh
	int 10h
	mov al, '<'
	mov ah, 0Eh
	int 10h
	jmp @@endProc

@@printHardNormal:
	push 14
	push 18
	push offset HardString
	call PrintStringAt

@@endProc:
	pop si dx cx bx ax
	ret
endp UpdateDifficultyMenuDisplay

; -----------------------------------------------
; Set difficulty parameters based on selected level
; -----------------------------------------------
proc SetDifficultyParameters
	push ax

	mov al, [DifficultyLevel]
	
	cmp al, 0  ; Easy
	je @@setEasy
	
	cmp al, 1  ; Medium
	je @@setMedium
	
	; Hard
	mov [byte ptr InvaderShotChance], 3
	jmp @@endProc

@@setEasy:
	mov [byte ptr InvaderShotChance], 20
	jmp @@endProc

@@setMedium:
	mov [byte ptr InvaderShotChance], 10

@@endProc:
	pop ax
	ret
endp SetDifficultyParameters

