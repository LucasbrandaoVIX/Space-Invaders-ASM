CODESEG

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


; -----------------------------------------------
; Print a string at specific screen coordinates with color
; Parameters on stack: line, column, string offset, color
; -----------------------------------------------
proc PrintStringAtWithColor
	push bp
	mov bp, sp
	push ax bx cx dx si

	; Get parameters from stack
	mov dh, [bp + 10] ; line
	mov dl, [bp + 8]  ; column
	mov si, [bp + 6]  ; string offset
	mov bl, [bp + 4]  ; color attribute

	; Set cursor position
	mov ah, 02h
	mov bh, 0
	int 10h

	; Print string character by character with color
@@printLoop:
	mov al, [si]
	cmp al, '$'
	je @@endPrint
	
	; Print character with color
	mov ah, 09h
	mov bh, 0
	mov cx, 1
	int 10h
	
	; Move cursor forward
	mov ah, 02h
	inc dl
	int 10h
	
	inc si
	jmp @@printLoop

@@endPrint:
	pop si dx cx bx ax
	pop bp
	ret 8
endp PrintStringAtWithColor

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
; Draw a decorative border around the menu
; -----------------------------------------------
proc DrawMenuBorder
	push ax bx cx dx si

	; Draw top border (cyan color)
	mov dh, 2
	mov dl, 15
	mov ah, 02h
	mov bh, 0
	int 10h
	
	mov cx, 50
	mov al, '='
	mov bl, 0Bh  ; Light cyan
@@topBorder:
	mov ah, 09h
	mov bh, 0
	push cx
	mov cx, 1
	int 10h
	pop cx
	
	; Move cursor
	mov ah, 02h
	inc dl
	int 10h
	loop @@topBorder

	; Draw side borders (yellow color)
	mov cx, 19  ; Height of menu area
	mov dh, 3   ; Starting row
@@sideBorders:
	push cx
	
	; Left border
	mov dl, 15
	mov ah, 02h
	mov bh, 0
	int 10h
	mov al, '|'
	mov ah, 09h
	mov bl, 0Eh  ; Yellow
	mov cx, 1
	int 10h
	
	; Right border
	mov dl, 64
	mov ah, 02h
	mov bh, 0
	int 10h
	mov al, '|'
	mov ah, 09h
	mov bl, 0Eh  ; Yellow
	mov cx, 1
	int 10h
	
	inc dh
	pop cx
	loop @@sideBorders

	; Draw bottom border (cyan color)
	mov dh, 22
	mov dl, 15
	mov ah, 02h
	mov bh, 0
	int 10h
	
	mov cx, 50
	mov al, '='
	mov bl, 0Bh  ; Light cyan
@@bottomBorder:
	mov ah, 09h
	mov bh, 0
	push cx
	mov cx, 1
	int 10h
	pop cx
	
	; Move cursor
	mov ah, 02h
	inc dl
	int 10h
	loop @@bottomBorder

	pop si dx cx bx ax
	ret
endp DrawMenuBorder

; -----------------------------------------------
; Print the difficulty selection menu
; -----------------------------------------------
proc PrintDifficultyMenu
	push ax bx cx dx

	; Clear screen using BIOS
	mov ah, 00h
	mov al, 03h  ; 80x25 color text mode
	int 10h

	; Draw decorative border
	call DrawMenuBorder

	; Print title with decorative elements (bright white on blue background)
	push 4
	push 30
	push offset MenuStars1
	push 0Dh  ; Light magenta
	call PrintStringAtWithColor
	
	push 5
	push 33
	push offset DifficultyTitleString
	push 0Fh  ; Bright white
	call PrintStringAtWithColor
	
	push 6
	push 30
	push offset MenuStars2
	push 0Dh  ; Light magenta
	call PrintStringAtWithColor

	; Print subtitle (light green)
	push 9
	push 31
	push offset SelectDifficultyString
	push 0Ah  ; Light green
	call PrintStringAtWithColor

	; Print options with highlighting
	call UpdateDifficultyMenuDisplay

	; Print instructions (gray color)
	push 19
	push 19
	push offset UseArrowKeysString
	push 07h  ; Light gray
	call PrintStringAtWithColor

	; Draw bottom decoration (cyan)
	push 21
	push 25
	push offset MenuBottomDecor
	push 0Bh  ; Light cyan
	call PrintStringAtWithColor

	pop dx cx bx ax
	ret
endp PrintDifficultyMenu

; -----------------------------------------------
; Update the difficulty menu display with current selection
; -----------------------------------------------
proc UpdateDifficultyMenuDisplay
	push ax bx cx dx si

	; Clear the options area first (wider area for better spacing)
	mov cx, 3  ; Clear 3 lines
	mov dh, 12 ; Start at line 12
@@clearLoop:
	push cx
	push dx
	
	mov dl, 18  ; Start clearing from column 18
	mov ah, 02h
	mov bh, 0
	int 10h
	
	mov cx, 44  ; Clear 44 characters (wider area)
@@clearLineLoop:
	mov al, ' '
	mov ah, 0Eh
	int 10h
	loop @@clearLineLoop
	
	pop dx
	pop cx
	inc dh
	loop @@clearLoop

	; Now print options (centered around column 40) with better styling
	; Easy option
	mov al, [SelectedMenuItem]
	cmp al, 0
	jne @@printEasyNormal
	
	; Print highlighted Easy with decorative brackets (bright yellow)
	mov dh, 12
	mov dl, 36
	mov ah, 02h
	mov bh, 0
	int 10h
	
	mov al, '<'
	mov ah, 09h
	mov bl, 0Eh  ; Yellow
	mov cx, 1
	int 10h
	
	; Move cursor
	mov ah, 02h
	inc dl
	int 10h
	
	mov al, ' '
	mov ah, 09h
	mov bl, 0Eh  ; Yellow
	mov cx, 1
	int 10h
	
	; Move cursor
	mov ah, 02h
	inc dl
	int 10h
	
	mov si, offset EasyString
@@printEasyHighlight:
	mov al, [si]
	cmp al, '$'
	je @@endEasyHighlight
	mov ah, 09h
	mov bl, 0Eh  ; Yellow
	mov cx, 1
	int 10h
	
	; Move cursor
	mov ah, 02h
	inc dl
	int 10h
	
	inc si
	jmp @@printEasyHighlight
@@endEasyHighlight:
	mov al, ' '
	mov ah, 09h
	mov bl, 0Eh  ; Yellow
	mov cx, 1
	int 10h
	
	; Move cursor
	mov ah, 02h
	inc dl
	int 10h
	
	mov al, '>'
	mov ah, 09h
	mov bl, 0Eh  ; Yellow
	mov cx, 1
	int 10h
	jmp @@printMedium

@@printEasyNormal:
	; Print normal Easy with spacing (white)
	push 12
	push 20
	push offset MenuSpacing
	push 07h  ; Light gray
	call PrintStringAtWithColor
	push 12
	push 38
	push offset EasyString
	push 07h  ; Light gray
	call PrintStringAtWithColor

@@printMedium:
	; Medium option
	mov al, [SelectedMenuItem]
	cmp al, 1
	jne @@printMediumNormal
	
	; Print highlighted Medium with decorative brackets (bright yellow)
	mov dh, 13
	mov dl, 35
	mov ah, 02h
	mov bh, 0
	int 10h
	
	mov al, '<'
	mov ah, 09h
	mov bl, 0Eh  ; Yellow
	mov cx, 1
	int 10h
	
	; Move cursor
	mov ah, 02h
	inc dl
	int 10h
	
	mov al, ' '
	mov ah, 09h
	mov bl, 0Eh  ; Yellow
	mov cx, 1
	int 10h
	
	; Move cursor
	mov ah, 02h
	inc dl
	int 10h
	
	mov si, offset MediumString
@@printMediumHighlight:
	mov al, [si]
	cmp al, '$'
	je @@endMediumHighlight
	mov ah, 09h
	mov bl, 0Eh  ; Yellow
	mov cx, 1
	int 10h
	
	; Move cursor
	mov ah, 02h
	inc dl
	int 10h
	
	inc si
	jmp @@printMediumHighlight
@@endMediumHighlight:
	mov al, ' '
	mov ah, 09h
	mov bl, 0Eh  ; Yellow
	mov cx, 1
	int 10h
	
	; Move cursor
	mov ah, 02h
	inc dl
	int 10h
	
	mov al, '>'
	mov ah, 09h
	mov bl, 0Eh  ; Yellow
	mov cx, 1
	int 10h
	jmp @@printHard

@@printMediumNormal:
	; Print normal Medium with spacing (white)
	push 13
	push 20
	push offset MenuSpacing
	push 07h  ; Light gray
	call PrintStringAtWithColor
	push 13
	push 37
	push offset MediumString
	push 07h  ; Light gray
	call PrintStringAtWithColor

@@printHard:
	; Hard option
	mov al, [SelectedMenuItem]
	cmp al, 2
	jne @@printHardNormal
	
	; Print highlighted Hard with decorative brackets (bright yellow)
	mov dh, 14
	mov dl, 36
	mov ah, 02h
	mov bh, 0
	int 10h
	
	mov al, '<'
	mov ah, 09h
	mov bl, 0Eh  ; Yellow
	mov cx, 1
	int 10h
	
	; Move cursor
	mov ah, 02h
	inc dl
	int 10h
	
	mov al, ' '
	mov ah, 09h
	mov bl, 0Eh  ; Yellow
	mov cx, 1
	int 10h
	
	; Move cursor
	mov ah, 02h
	inc dl
	int 10h
	
	mov si, offset HardString
@@printHardHighlight:
	mov al, [si]
	cmp al, '$'
	je @@endHardHighlight
	mov ah, 09h
	mov bl, 0Eh  ; Yellow
	mov cx, 1
	int 10h
	
	; Move cursor
	mov ah, 02h
	inc dl
	int 10h
	
	inc si
	jmp @@printHardHighlight
@@endHardHighlight:
	mov al, ' '
	mov ah, 09h
	mov bl, 0Eh  ; Yellow
	mov cx, 1
	int 10h
	
	; Move cursor
	mov ah, 02h
	inc dl
	int 10h
	
	mov al, '>'
	mov ah, 09h
	mov bl, 0Eh  ; Yellow
	mov cx, 1
	int 10h
	jmp @@endProc

@@printHardNormal:
	; Print normal Hard with spacing (white)
	push 14
	push 20
	push offset MenuSpacing
	push 07h  ; Light gray
	call PrintStringAtWithColor
	push 14
	push 38
	push offset HardString
	push 07h  ; Light gray
	call PrintStringAtWithColor

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

